/**
 * # terraform-fortios-advpn-sdwan-spoke
 * 
 * Uses forked version of fortios provider
 *
 * Requires FortiOS >= 7.0.3
 *
 * Uses sub-table resources in BGP and SDWAN parent tables. Do not mix and match here.
 * 
 * Intended for use with https://registry.terraform.io/modules/poroping/advpn-sdwan-hub/fortios
 *
 */


terraform {
  required_providers {
    fortios = {
      source  = "poroping/fortios"
      version = ">= 3.1.4"
    }
  }
}

locals {
  advpn0 = [for i, v in var.interfaces : merge(var.interfaces[i], var.hub_links[i])]
  advpn1 = [for v in local.advpn0 : merge(v, {
    advpn_spoke_id   = "${tostring(v.advpn_id)}${tostring(v.interface_id)}"
    advpn_spoke_name = "${v.advpn_name}-${tostring(v.interface_id)}"
  })]
  advpn = { for advpn in local.advpn1 : "${advpn.remote_gw}_${advpn.advpn_id}_${advpn.interface_id}" => advpn }
}

resource "fortios_vpnipsec_phase1interface" "phase1" {
  for_each = local.advpn

  vdomparam = var.vdom

  name                     = each.value.advpn_spoke_name
  type                     = "static"
  interface                = each.value.interface_name
  local_gw                 = each.value.local_gw == "" ? null : each.value.local_gw
  ike_version              = 2
  peertype                 = "any"
  network_overlay          = "enable"
  network_id               = each.value.advpn_id
  mode_cfg                 = "enable"
  net_device               = "enable"
  proposal                 = var.ipsec_proposal
  add_route                = "disable"
  dpd                      = "on-demand"
  dpd_retryinterval        = "2 500"
  dpd_retrycount           = 3
  auto_discovery_receiver  = "enable"
  auto_discovery_shortcuts = "dependent"
  psksecret                = var.ipsec_psk
  idle_timeout             = "enable"
  idle_timeoutinterval     = 5
  remote_gw                = each.value.remote_gw
  ip_fragmentation         = var.ip_fragmentation == null ? null : var.ip_fragmentation
}

resource "fortios_vpnipsec_phase2interface" "phase2" {
  for_each = local.advpn

  vdomparam = var.vdom

  name       = fortios_vpnipsec_phase1interface.phase1[each.key].name
  phase1name = fortios_vpnipsec_phase1interface.phase1[each.key].name
  proposal   = fortios_vpnipsec_phase1interface.phase1[each.key].proposal
  pfs        = "enable"
  dhgrp      = var.ipsec_dhgrp
}

resource "fortios_system_interface" "vpn_interface" {
  for_each = local.advpn

  allow_append = true

  description = "Managed by Terraform."
  name        = fortios_vpnipsec_phase1interface.phase1[each.key].name
  allowaccess = "ping"
  vdom        = var.vdom
}

resource "fortios_routerbgp_neighbor" "neighbor" {
  for_each = local.advpn

  allow_append = true
  vdomparam    = var.vdom

  ip                          = each.value.tunnel_ip
  interface                   = fortios_vpnipsec_phase1interface.phase1[each.key].name
  update_source               = fortios_vpnipsec_phase1interface.phase1[each.key].name
  remote_as                   = var.bgp_as
  connect_timer               = 1
  link_down_failover          = "enable"
  additional_path             = "receive"
  capability_graceful_restart = "enable"
  capability_route_refresh    = "enable"
  soft_reconfiguration        = "enable"
  keep_alive_timer            = 7
  holdtime_timer              = 21
  advertisement_interval      = 5
  route_map_in                = fortios_router_routemap.route_map.name
}

resource "fortios_routerbgp_network" "networks" {
  for_each = var.networks

  vdomparam = var.vdom

  prefix = each.key
}

resource "fortios_routerbgp_network" "overlay_networks" {
  for_each = var.overlay_networks

  vdomparam = var.vdom

  prefix = each.key
  # route_map = 
}

resource "fortios_routerbgp_network" "underlay_networks" {
  for_each = var.underlay_networks

  vdomparam = var.vdom

  prefix = each.key
  # route_map = 
}

resource "fortios_system_sdwan_zone" "zone" {
  vdomparam    = var.vdom
  allow_append = true

  name = "sdwan-hub${tostring(var.hub_id)}"
}

resource "fortios_system_sdwan_members" "spoke" {
  for_each = local.advpn

  vdomparam = var.vdom
  # allow_append = true

  # seq_num   = each.value.advpn_spoke_id
  interface = fortios_vpnipsec_phase1interface.phase1[each.key].name
  zone      = fortios_system_sdwan_zone.zone.name
  cost      = each.value.cost
}

resource "fortios_system_sdwan_health_check" "spoke" {
  vdomparam    = var.vdom
  allow_append = true

  name                = "sla_hub${tostring(var.hub_id)}"
  server              = split("/", var.hub_loopback)[0]
  update_static_route = "disable"
  sla_fail_log_period = 60
  sla_pass_log_period = 60

  dynamic "members" {
    for_each = fortios_system_sdwan_members.spoke

    content {
      seq_num = members.value.seq_num
    }
  }

  sla {
    id                   = var.hub_id
    latency_threshold    = var.hub_sla.latency
    jitter_threshold     = var.hub_sla.jitter
    packetloss_threshold = var.hub_sla.packetloss
  }

}

resource "fortios_router_prefixlist" "pl_all" {
  allow_append = true

  name = "pl-${local.advpn[keys(local.advpn)[0]].advpn_spoke_name}-all"

  rule {
    id     = 1
    action = "permit"
    prefix = "0.0.0.0/0"
    le     = 32
  }
}

resource "fortios_router_routemap" "route_map" {
  allow_append = true

  name = "tag-${local.advpn[keys(local.advpn)[0]].advpn_spoke_name}"

  rule {
    id               = 10
    match_ip_address = fortios_router_prefixlist.pl_all.name
    set_route_tag    = local.advpn[keys(local.advpn)[0]].advpn_id
  }
}

resource "fortios_system_sdwan_service" "spoke" {
  vdomparam = var.vdom

  name                     = "dyn-hub${tostring(var.hub_id)}"
  hold_down_time           = 20
  mode                     = "sla"
  route_tag                = local.advpn[keys(local.advpn)[0]].advpn_id
  sla_compare_method       = "order"
  minimum_sla_meet_members = 0
  tie_break                = "fib-best-match"

  priority_zone {
    name = fortios_system_sdwan_zone.zone.name // 7.0 only
  }

  sla {
    health_check = fortios_system_sdwan_health_check.spoke.name
    id           = var.hub_id
  }

}

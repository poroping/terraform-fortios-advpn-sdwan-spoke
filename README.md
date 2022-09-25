<!-- BEGIN_TF_DOCS -->
# terraform-fortios-advpn-sdwan-spoke

Uses forked version of fortios provider

Requires FortiOS >= 7.0.3

Uses sub-table resources in BGP and SDWAN parent tables. Do not mix and match here.

Intended for use with https://registry.terraform.io/modules/poroping/advpn-sdwan-hub/fortios

### Example Usage:
```hcl
terraform {
  required_version = ">= 1.0.1"
  backend "local" {}
  required_providers {
    fortios = {
      source  = "poroping/fortios"
      version = ">= 3.1.4"
    }
  }
}

### Hub configuration
## Assumes hub has been created with sister module registry.terraform.io/modules/poroping/advpn-sdwan-hub/fortios
## Hub config has been abbreviated for readbility and is incomplete

data "fortios_system_interface" "hub1_1" {
  provider = fortios.hub1
  name     = "port1"
}

data "fortios_system_interface" "hub1_2" {
  provider = fortios.hub1
  name     = "port2"
}

locals {
  hub1_interfaces = [
    {
      interface_name = data.fortios_system_interface.hub1_1.name
      interface_id   = 1
      local_gw       = null
      cost           = null
      nat_ip         = null
      tunnel_subnet  = "169.254.101.0/24"
    },
    {
      interface_name = data.fortios_system_interface.hub1_2.name
      interface_id   = 2
      local_gw       = null
      cost           = null
      nat_ip         = null
      tunnel_subnet  = "169.254.102.0/24"
    }
  ]
  hub1_bgp_as = 64420
}

module "advpnhub1" {
  providers = {
    fortios = fortios.hub1
  }
  source  = "poroping/advpn-sdwan-hub/fortios"
  version = "~> 1.0.0"

  bgp_as          = local.hub1_bgp_as
  interfaces      = local.hub1_interfaces
  hub_id          = 1
  vdom            = "root"
  sla_loopback_ip = "169.254.255.1/32"
}

### Spoke

provider "fortios" {
  alias    = "spoke1"
  hostname = "192.168.1.99"
  token    = "supertokens"
  vdom     = "root"
  insecure = "true"
}

provider "fortios" {
  alias    = "spoke2"
  hostname = "192.168.2.99"
  token    = "supertokens"
  vdom     = "root"
  insecure = "true"
}

provider "fortios" {
  alias    = "spoke3"
  hostname = "192.168.3.99"
  token    = "supertokens"
  vdom     = "root"
  insecure = "true"
}

data "fortios_system_interface" "spoke1" {
  provider = fortios.spoke1

  name = "port1"
}

data "fortios_system_interface" "spoke1_2" {
  provider = fortios.spoke1

  name = "wwan"
}

data "fortios_system_interface" "spoke2" {
  provider = fortios.spoke2

  name = "wan1"
}

data "fortios_system_interface" "spoke2_2" {
  provider = fortios.spoke2

  name = "wan2"
}

data "fortios_system_interface" "spoke3" {
  provider = fortios.spoke3

  name = "vlanx"
}

data "fortios_system_interface" "spoke3_2" {
  provider = fortios.spoke3

  name = "vlany"
}

locals {
  spoke1_interfaces = [
    {
      interface_name = data.fortios_system_interface.spoke1.name
      interface_id   = 1
      local_gw       = null
      cost           = 10
    },
    {
      interface_name = data.fortios_system_interface.spoke1_2.name
      interface_id   = 2
      local_gw       = null
      cost           = 100
    },
  ]
  spoke2_interfaces = [
    {
      interface_name = data.fortios_system_interface.spoke2.name
      interface_id   = 1
      local_gw       = null
      cost           = null
    },
    {
      interface_name = data.fortios_system_interface.spoke2_2.name
      interface_id   = 2
      local_gw       = null
      cost           = null
    },
  ]
  spoke3_interfaces = [
    {
      interface_name = data.fortios_system_interface.spoke3.name
      interface_id   = 1
      local_gw       = null
      cost           = 10
    },
    {
      interface_name = data.fortios_system_interface.spoke3_2.name
      interface_id   = 2
      local_gw       = null
      cost           = 20
    },
  ]
}

### BGP Prereqs, only single device shown for brevity

resource "fortios_router_bgp" "spoke1" {
  provider = fortios.spoke1

  vdomparam = "root"

  ibgp_multipath         = "enable"
  router_id              = "192.168.1.255"
  additional_path        = "enable"
  additional_path_select = 4
  as                     = local.hub1_bgp_as
  recursive_next_hop     = "enable" # if not 7.x then need to static route all tunnel subnets towards hub.

  # ignore subtables
  lifecycle {
    ignore_changes = [
      aggregate_address,
      aggregate_address6,
      network,
      network6,
      neighbor,
      neighbor_group,
      neighbor_range,
      neighbor_range6,
      admin_distance
    ]
  }
}

module "advpnspoke1" {
  providers = {
    fortios = fortios.spoke1
  }

  source  = "poroping/advpn-sdwan-spoke/fortios"
  version = "~> 0.0.1"

  bgp_as       = local.hub1_bgp_as
  interfaces   = local.spoke1_interfaces
  hub_links    = module.advpnhub1.hub.links
  hub_id       = module.advpnhub1.hub.hub_id
  hub_loopback = module.advpnhub1.hub.hub_loopback
  vdom         = "root"
  spoke_id     = 1
  ipsec_psk    = module.advpnhub1.psk
}

module "advpnspoke2" {
  providers = {
    fortios = fortios.spoke2
  }

  source  = "poroping/advpn-sdwan-spoke/fortios"
  version = "~> 0.0.1"

  bgp_as       = local.hub1_bgp_as
  interfaces   = local.spoke2_interfaces
  hub_links    = module.advpnhub1.hub.links
  hub_id       = module.advpnhub1.hub.hub_id
  hub_loopback = module.advpnhub1.hub.hub_loopback
  vdom         = "root"
  spoke_id     = 2
  ipsec_psk    = module.advpnhub1.psk
  hub_sla = {
    "jitter" : 30,
    "latency" : 150,
    "packetloss" : 1
  }
}

module "advpnspoke3" {
  providers = {
    fortios = fortios.spoke3
  }

  source  = "poroping/advpn-sdwan-spoke/fortios"
  version = "~> 0.0.1"

  bgp_as       = local.hub1_bgp_as
  interfaces   = local.spoke3_interfaces
  hub_links    = module.advpnhub1.hub.links
  hub_id       = module.advpnhub1.hub.hub_id
  hub_loopback = module.advpnhub1.hub.hub_loopback
  vdom         = "root"
  spoke_id     = 3
  ipsec_psk    = module.advpnhub1.psk
  hub_sla = {
    "jitter" : 20,
    "latency" : 100,
    "packetloss" : 0
  }
}

### Ensure SDWAN is enabled
### Ensure firewall policies are created
### Suggested SNAT route change enabled or blackhole routes utilised
```

## Providers

| Name | Version |
|------|---------|
| <a name="provider_fortios"></a> [fortios](#provider\_fortios) | >= 3.1.4 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_hub_id"></a> [hub\_id](#input\_hub\_id) | Hub ID - single digit int. | `number` | n/a | yes |
| <a name="input_hub_links"></a> [hub\_links](#input\_hub\_links) | Set of links on hub to peer with. | <pre>list(object({<br>    advpn_id   = number<br>    advpn_name = string<br>    remote_gw  = string<br>    tunnel_ip  = string<br>    }<br>  ))</pre> | n/a | yes |
| <a name="input_hub_loopback"></a> [hub\_loopback](#input\_hub\_loopback) | Hub loopback IP address | `string` | n/a | yes |
| <a name="input_interfaces"></a> [interfaces](#input\_interfaces) | Set of interfaces to use to peer with hubs. | <pre>list(object({<br>    cost           = number<br>    interface_name = string<br>    interface_id   = number<br>    local_gw       = string<br>    }<br>  ))</pre> | n/a | yes |
| <a name="input_ipsec_psk"></a> [ipsec\_psk](#input\_ipsec\_psk) | Pre-shared key for IPSEC tunnels. | `string` | n/a | yes |
| <a name="input_spoke_id"></a> [spoke\_id](#input\_spoke\_id) | Spoke ID - Between 1 and 254. | `number` | n/a | yes |
| <a name="input_bgp_as"></a> [bgp\_as](#input\_bgp\_as) | BGP AS to use for ADVPN. | `number` | `65000` | no |
| <a name="input_hub_sla"></a> [hub\_sla](#input\_hub\_sla) | Hub SLA values. | <pre>object({<br>    latency    = number<br>    jitter     = number<br>    packetloss = number<br>  })</pre> | <pre>{<br>  "jitter": 5,<br>  "latency": 50,<br>  "packetloss": 0<br>}</pre> | no |
| <a name="input_ip_fragmentation"></a> [ip\_fragmentation](#input\_ip\_fragmentation) | Determine whether IP packets are fragmented before or after IPsec encapsulation. | `string` | `null` | no |
| <a name="input_ipsec_dhgrp"></a> [ipsec\_dhgrp](#input\_ipsec\_dhgrp) | List of dhgrp separated by whitespace. | `string` | `"14"` | no |
| <a name="input_ipsec_proposal"></a> [ipsec\_proposal](#input\_ipsec\_proposal) | List of proposals separated by whitespace. | `string` | `"aes256-sha256"` | no |
| <a name="input_networks"></a> [networks](#input\_networks) | A set of BGP networks. | `set(string)` | `[]` | no |
| <a name="input_overlay_networks"></a> [overlay\_networks](#input\_overlay\_networks) | A set of overlay networks. | `set(string)` | `[]` | no |
| <a name="input_underlay_networks"></a> [underlay\_networks](#input\_underlay\_networks) | A set of underlay networks. | `set(string)` | `[]` | no |
| <a name="input_vdom"></a> [vdom](#input\_vdom) | VDOM to apply configuration. | `string` | `"root"` | no |


<!-- END_TF_DOCS -->    
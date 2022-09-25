variable "networks" {
  type        = set(string)
  description = "A set of BGP networks."
  default     = []
}

variable "overlay_networks" {
  type        = set(string)
  description = "A set of overlay networks."
  default     = []
}

variable "underlay_networks" {
  type        = set(string)
  description = "A set of underlay networks."
  default     = []
}

variable "vdom" {
  type        = string
  description = "VDOM to apply configuration."
  default     = "root"
}

variable "interfaces" {
  description = "Set of interfaces to use to peer with hubs."
  type = list(object({
    cost           = number
    interface_name = string
    interface_id   = number
    local_gw       = string
    }
  ))
}

variable "bgp_as" {
  type        = number
  description = "BGP AS to use for ADVPN."
  default     = 65000
}

variable "hub_links" {
  description = "Set of links on hub to peer with."
  type = list(object({
    advpn_id   = number
    advpn_name = string
    remote_gw  = string
    tunnel_ip  = string
    }
  ))
}

variable "hub_loopback" {
  description = "Hub loopback IP address"
  type        = string
}

variable "hub_id" {
  type = number
  validation {
    condition     = var.hub_id >= 1 && var.hub_id <= 9
    error_message = "Value must be between 1 and 9 inclusive."
  }
  description = "Hub ID - single digit int."
}

variable "hub_sla" {
  description = "Hub SLA values."
  type = object({
    latency    = number
    jitter     = number
    packetloss = number
  })
  default = {
    jitter     = 5
    latency    = 50
    packetloss = 0
  }
}

variable "spoke_id" {
  type = number
  validation {
    condition     = var.spoke_id >= 1 && var.spoke_id <= 254
    error_message = "Value must be between 1 and 254 inclusive."
  }
  description = "Spoke ID - Between 1 and 254."
}

variable "ipsec_proposal" {
  type        = string
  description = "List of proposals separated by whitespace."
  default     = "aes256-sha256"
}

variable "ipsec_psk" {
  type        = string
  description = "Pre-shared key for IPSEC tunnels."
}

variable "ipsec_dhgrp" {
  type        = string
  description = "List of dhgrp separated by whitespace."
  default     = "14"
}

variable "ip_fragmentation" {
  type        = string
  description = "Determine whether IP packets are fragmented before or after IPsec encapsulation."
  default     = null
}

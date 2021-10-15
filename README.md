<!-- BEGIN_TF_DOCS -->
# terraform-fortios-advpn-sdwan-hub

Requires forked version of fortios provider

Does stuff.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_fortios"></a> [fortios](#provider\_fortios) | >= 2.3.4 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_hub_id"></a> [hub\_id](#input\_hub\_id) | n/a | `number` | n/a | yes |
| <a name="input_hub_links"></a> [hub\_links](#input\_hub\_links) | Set of links on hub to peer with. | <pre>list(object({<br>    advpn_id   = number<br>    advpn_name = string<br>    remote_gw  = string<br>    tunnel_ip  = string<br>    }<br>  ))</pre> | n/a | yes |
| <a name="input_hub_loopback"></a> [hub\_loopback](#input\_hub\_loopback) | n/a | `string` | n/a | yes |
| <a name="input_interfaces"></a> [interfaces](#input\_interfaces) | Set of interfaces to use to peer with hubs. | <pre>list(object({<br>    interface_name = string<br>    interface_id   = number<br>    local_gw       = string # add cost<br>    }<br>  ))</pre> | n/a | yes |
| <a name="input_spoke_id"></a> [spoke\_id](#input\_spoke\_id) | n/a | `number` | n/a | yes |
| <a name="input_vdom"></a> [vdom](#input\_vdom) | n/a | `string` | n/a | yes |
| <a name="input_bgp_as"></a> [bgp\_as](#input\_bgp\_as) | n/a | `number` | `65000` | no |
| <a name="input_bgp_router_id"></a> [bgp\_router\_id](#input\_bgp\_router\_id) | n/a | `string` | `null` | no |
| <a name="input_interregional_dynamic_vpn_networks"></a> [interregional\_dynamic\_vpn\_networks](#input\_interregional\_dynamic\_vpn\_networks) | Set of networks used for dynamic vpn in other regions. That are connected to the hub. | `set(string)` | `[]` | no |
| <a name="input_networks"></a> [networks](#input\_networks) | n/a | `set(string)` | `[]` | no |
| <a name="input_overlay_networks"></a> [overlay\_networks](#input\_overlay\_networks) | A set of overlay networks. | `set(string)` | `[]` | no |
| <a name="input_underlay_networks"></a> [underlay\_networks](#input\_underlay\_networks) | A set of underlay networks. | `set(string)` | `[]` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | ~> 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [cloudflare_dns_record.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/dns_record) | resource |
| [cloudflare_zone.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/data-sources/zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_dns_domain"></a> [dns\_domain](#input\_dns\_domain) | The DNS domain name under which the DNS record will be created.<br/>Example: "example.com" | `string` | n/a | yes |
| <a name="input_dns_record_name"></a> [dns\_record\_name](#input\_dns\_record\_name) | The DNS record name (subdomain or hostname) to create or manage.<br/>Example: "www" or "app"<br/>Defaults to "*" | `string` | `"*"` | no |
| <a name="input_dns_record_type"></a> [dns\_record\_type](#input\_dns\_record\_type) | The DNS record type (e.g., A, AAAA, CNAME).<br/>Defaults to "A" | `string` | `"A"` | no |
| <a name="input_dns_record_value"></a> [dns\_record\_value](#input\_dns\_record\_value) | The value of the DNS record, which can be:<br/>  - An IPv4 address (e.g., 192.168.0.1)<br/>  - An IPv6 address (e.g., 2001:0db8::1)<br/>  - A hostname (e.g., example.com or sub.domain.local) | `string` | n/a | yes |
| <a name="input_dns_ttl"></a> [dns\_ttl](#input\_dns\_ttl) | The TTL (time to live) for the DNS record in seconds.<br/>Must be a positive integer, typically between 30 and 86400.<br/>Defaults to 60 seconds. | `number` | `1` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
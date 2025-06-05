<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | ~> 6.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_dns_record_set.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_record_set) | resource |
| [google_project_iam_custom_role.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_custom_role) | resource |
| [google_project_iam_member.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_service_account.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account_key.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_key) | resource |
| [google_dns_managed_zones.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/dns_managed_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_dns_domain"></a> [dns\_domain](#input\_dns\_domain) | The DNS domain name under which the DNS record will be created.<br/>Example: "example.com" | `string` | n/a | yes |
| <a name="input_dns_record_name"></a> [dns\_record\_name](#input\_dns\_record\_name) | The DNS record name (subdomain or hostname) to create or manage.<br/>Example: "www" or "app"<br/>Defaults to "*" | `string` | `"*"` | no |
| <a name="input_dns_record_type"></a> [dns\_record\_type](#input\_dns\_record\_type) | The DNS record type (e.g., A, AAAA, CNAME).<br/>Defaults to "A" | `string` | `"A"` | no |
| <a name="input_dns_record_value"></a> [dns\_record\_value](#input\_dns\_record\_value) | The value of the DNS record, which can be:<br/>  - An IPv4 address (e.g., 192.168.0.1)<br/>  - An IPv6 address (e.g., 2001:0db8::1)<br/>  - A hostname (e.g., example.com or sub.domain.local) | `string` | n/a | yes |
| <a name="input_dns_ttl"></a> [dns\_ttl](#input\_dns\_ttl) | The TTL (time to live) for the DNS record in seconds.<br/>Must be a positive integer, typically between 30 and 86400.<br/>Defaults to 60 seconds. | `number` | `60` | no |
| <a name="input_gcp_project"></a> [gcp\_project](#input\_gcp\_project) | The Google Cloud Project ID to use for creating and managing resources.<br/>This should be the unique identifier of your GCP project.<br/>If not provided (null), some modules might attempt to infer the project from<br/>your environment or credentials.<br/><br/>Format requirements:<br/>  - Length between 6 and 30 characters<br/>  - Lowercase letters, digits, and hyphens only<br/>  - Must start with a lowercase letter<br/>  - Cannot end with a hyphen | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_gcp_service_account_key"></a> [gcp\_service\_account\_key](#output\_gcp\_service\_account\_key) | n/a |
<!-- END_TF_DOCS -->
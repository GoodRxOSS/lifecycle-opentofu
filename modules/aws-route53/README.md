<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_access_key.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_access_key) | resource |
| [aws_iam_user.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user) | resource |
| [aws_iam_user_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user_policy) | resource |
| [aws_route53_record.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_route53_zone.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_dns_domain"></a> [dns\_domain](#input\_dns\_domain) | The DNS domain name under which the DNS record will be created.<br/>Example: "example.com" | `string` | n/a | yes |
| <a name="input_dns_record_name"></a> [dns\_record\_name](#input\_dns\_record\_name) | The DNS record name (subdomain or hostname) to create or manage.<br/>Example: "www" or "app"<br/>Defaults to "*" | `string` | `"*"` | no |
| <a name="input_dns_record_type"></a> [dns\_record\_type](#input\_dns\_record\_type) | The DNS record type (e.g., A, AAAA, CNAME).<br/>Defaults to "A" | `string` | `"A"` | no |
| <a name="input_dns_record_value"></a> [dns\_record\_value](#input\_dns\_record\_value) | The value of the DNS record, which can be:<br/>  - An IPv4 address (e.g., 192.168.0.1)<br/>  - An IPv6 address (e.g., 2001:0db8::1)<br/>  - A hostname (e.g., example.com or sub.domain.local) | `string` | n/a | yes |
| <a name="input_dns_ttl"></a> [dns\_ttl](#input\_dns\_ttl) | The TTL (time to live) for the DNS record in seconds.<br/>Must be a positive integer, typically between 30 and 86400.<br/>Defaults to 60 seconds. | `number` | `60` | no |
| <a name="input_route53_iam_user_name"></a> [route53\_iam\_user\_name](#input\_route53\_iam\_user\_name) | The name of the IAM user that will be used to manage Route53 DNS records.<br/>This user should have the necessary permissions to create, update, and delete DNS entries.<br/>Default is "cert-manager". | `string` | `"cert-manager"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_access_key_id"></a> [aws\_access\_key\_id](#output\_aws\_access\_key\_id) | The AWS access key ID for the created IAM user.<br/>This is used to authenticate AWS API requests.<br/>Make sure to store this value securely. |
| <a name="output_aws_secret_access_key"></a> [aws\_secret\_access\_key](#output\_aws\_secret\_access\_key) | The AWS secret access key associated with the access key ID.<br/>This is sensitive information required for authentication with AWS.<br/>Keep this value secure and avoid hardcoding it in version control or logs. |
| <a name="output_route53_zone_id"></a> [route53\_zone\_id](#output\_route53\_zone\_id) | The ID of the Route53 hosted zone that is being managed.<br/>This value is used to associate DNS records with the correct hosted zone. |
<!-- END_TF_DOCS -->
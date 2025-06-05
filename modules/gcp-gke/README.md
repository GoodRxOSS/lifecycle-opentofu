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
| [google_container_cluster.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster) | resource |
| [google_container_node_pool.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_node_pool) | resource |
| [google_project_iam_member.metrics](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_service_account.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_client_config.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |
| [google_project.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name of the GKE cluster.<br/>This value is used to identify the cluster within GCP and should be unique<br/>within the selected project and region.<br/>Example: "application-gke" | `string` | `"application-gke"` | no |
| <a name="input_gcp_region"></a> [gcp\_region](#input\_gcp\_region) | The Google Cloud region or zone where the GKE cluster is deployed.<br/>Example: "us-central1" or "us-central1-b" | `string` | `"us-central1-b"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_ca_certificate"></a> [cluster\_ca\_certificate](#output\_cluster\_ca\_certificate) | The base64-decoded certificate authority (CA) certificate for the GKE cluster.<br/>Used for securely verifying the cluster's API server identity when authenticating clients. |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | The public endpoint URL used to connect to the GKE cluster's Kubernetes API server.<br/>This value is required when configuring kubectl or other Kubernetes clients. |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | The name of the created Google Kubernetes Engine (GKE) cluster.<br/>Useful for referencing the cluster by name in external modules or scripts. |
| <a name="output_cluster_token"></a> [cluster\_token](#output\_cluster\_token) | The OAuth2 access token for the active Google Cloud user account.<br/>This token can be used for authenticating against the Kubernetes API,<br/>typically passed as a Bearer token in client requests. Marked as sensitive. |
<!-- END_TF_DOCS -->
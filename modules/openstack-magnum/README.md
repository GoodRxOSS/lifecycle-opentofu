<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_openstack"></a> [openstack](#requirement\_openstack) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_openstack"></a> [openstack](#provider\_openstack) | ~> 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [openstack_compute_keypair_v2.this](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/compute_keypair_v2) | resource |
| [openstack_containerinfra_cluster_v1.this](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/containerinfra_cluster_v1) | resource |
| [openstack_containerinfra_clustertemplate_v1.this](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/containerinfra_clustertemplate_v1) | resource |
| [openstack_containerinfra_nodegroup_v1.this](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/containerinfra_nodegroup_v1) | resource |
| [openstack_networking_network_v2.internal](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/networking_network_v2) | resource |
| [openstack_networking_router_interface_v2.this](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/networking_router_interface_v2) | resource |
| [openstack_networking_router_v2.external](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/networking_router_v2) | resource |
| [openstack_networking_subnet_v2.internal](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/networking_subnet_v2) | resource |
| [openstack_compute_flavor_v2.m1_medium](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/data-sources/compute_flavor_v2) | data source |
| [openstack_compute_flavor_v2.m1_small](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/data-sources/compute_flavor_v2) | data source |
| [openstack_identity_project_v3.this](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/data-sources/identity_project_v3) | data source |
| [openstack_networking_network_v2.external](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/data-sources/networking_network_v2) | data source |
| [openstack_networking_subnet_ids_v2.external](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/data-sources/networking_subnet_ids_v2) | data source |
| [openstack_networking_subnet_v2.external](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/data-sources/networking_subnet_v2) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_desired_size"></a> [cluster\_desired\_size](#input\_cluster\_desired\_size) | The desired number of worker nodes in the node group at startup.<br/>This sets the initial node count in the EKS node group. | `number` | `2` | no |
| <a name="input_cluster_max_size"></a> [cluster\_max\_size](#input\_cluster\_max\_size) | The maximum number of nodes the EKS node group can scale up to.<br/>    Useful for configuring cluster autoscaler or other capacity limits. | `number` | `7` | no |
| <a name="input_cluster_min_size"></a> [cluster\_min\_size](#input\_cluster\_min\_size) | The minimum number of nodes in the EKS node group.<br/>    Cluster autoscaler or node group logic will not scale below this value. | `number` | `2` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name of the OpenStack Magnum COE (Container Orchestration Engine) cluster.<br/>This name is used to identify the cluster within the OpenStack project and will <br/>be visible in the 'openstack coe cluster list' output.<br/>Must start with a letter and contain only alphanumeric characters or dashes. | `string` | `"k8s"` | no |
| <a name="input_network_external_name"></a> [network\_external\_name](#input\_network\_external\_name) | The name of the OpenStack external network. Used as the 'name' attribute for the network resource. | `string` | `"external"` | no |
| <a name="input_network_internal_name"></a> [network\_internal\_name](#input\_network\_internal\_name) | The name of the OpenStack internal network. Used as the 'name' attribute for the network resource. | `string` | `"internal"` | no |
| <a name="input_network_subnets"></a> [network\_subnets](#input\_network\_subnets) | A map of subnet names to CIDR blocks used within the network.<br/>The key is the subnet name (must be URL-safe), and the value is a valid IPv4 CIDR. | `map(string)` | <pre>{<br/>  "internal-1": "192.168.111.0/24",<br/>  "internal-2": "192.168.112.0/24",<br/>  "internal-3": "192.168.113.0/24"<br/>}</pre> | no |
| <a name="input_project"></a> [project](#input\_project) | The name of the OpenStack project (tenant). <br/>Must be URL-safe and follow corporate naming conventions. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | The name of the OpenStack region. Standard default is RegionOne. | `string` | `"RegionOne"` | no |
| <a name="input_ssh_public_key"></a> [ssh\_public\_key](#input\_ssh\_public\_key) | The content of the SSH public key (e.g., contents of ~/.ssh/id\_rsa.pub). <br/>Supports RSA, ECDSA, and ED25519 formats. | `string` | `null` | no |
| <a name="input_ssh_public_key_path"></a> [ssh\_public\_key\_path](#input\_ssh\_public\_key\_path) | The local filesystem path to the SSH public key file. | `string` | `"~/.ssh/id_rsa.pub"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_ca_certificate"></a> [cluster\_ca\_certificate](#output\_cluster\_ca\_certificate) | The Root CA certificate (PEM format) used to verify the TLS connection to the cluster API server.<br/>Required for secure communication and to prevent man-in-the-middle attacks. |
| <a name="output_cluster_client_certificate"></a> [cluster\_client\_certificate](#output\_cluster\_client\_certificate) | The client certificate (PEM format) used for authenticating the user or service account against the Kubernetes API.<br/>Combined with the client key, it provides identity for the connection. |
| <a name="output_cluster_client_key"></a> [cluster\_client\_key](#output\_cluster\_client\_key) | The private key for the client certificate. <br/>This is a sensitive value used for cryptographic authentication to the cluster. |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | The Kubernetes API server endpoint URL. <br/>This is the address used by kubectl and other clients to communicate with the cluster control plane. |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | The name of the OpenStack Magnum Kubernetes cluster. <br/>Used to identify the cluster within the Container Infrastructure Management service. |
| <a name="output_cluster_raw_config"></a> [cluster\_raw\_config](#output\_cluster\_raw\_config) | The full, ready-to-use Kubeconfig file in YAML format. <br/>Contains all necessary credentials, endpoints, and context to access the cluster immediately. |
<!-- END_TF_DOCS -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | ~> 4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_eks_access_entry.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_entry) | resource |
| [aws_eks_access_policy_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_policy_association) | resource |
| [aws_eks_addon.ebs_csi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster) | resource |
| [aws_eks_node_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group) | resource |
| [aws_iam_openid_connect_provider.oidc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_role.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.ebs_csi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.node_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ebs_csi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_internet_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_route.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_subnet.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_eks_cluster_auth.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_eks_cluster_versions.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_versions) | data source |
| [tls_certificate.oidc](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/certificate) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region where the EKS cluster and related resources will be deployed.<br/>Example: "us-east-1", "eu-west-1", "us-west-2" | `string` | `"us-west-2"` | no |
| <a name="input_cluster_desired_size"></a> [cluster\_desired\_size](#input\_cluster\_desired\_size) | The desired number of worker nodes in the node group at startup.<br/>This sets the initial node count in the EKS node group. | `number` | `2` | no |
| <a name="input_cluster_max_size"></a> [cluster\_max\_size](#input\_cluster\_max\_size) | The maximum number of nodes the EKS node group can scale up to.<br/>    Useful for configuring cluster autoscaler or other capacity limits. | `number` | `7` | no |
| <a name="input_cluster_min_size"></a> [cluster\_min\_size](#input\_cluster\_min\_size) | The minimum number of nodes in the EKS node group.<br/>    Cluster autoscaler or node group logic will not scale below this value. | `number` | `1` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name of the Amazon EKS cluster.<br/>Used to identify the cluster across AWS services and Terraform resources.<br/>Must consist of alphanumeric characters, dashes, and be 1–100 characters long. | `string` | `"eks-cluster"` | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | The Kubernetes version to use for the EKS control plane.<br/>If not specified, AWS will use the default version.<br/>Example valid values: "1.27", "1.28", "1.29" | `string` | `null` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The CIDR block for the VPC to be used by the EKS cluster.<br/>Must be a valid CIDR notation (e.g., 10.0.0.0/16). | `string` | `"172.32.0.0/16"` | no |
| <a name="input_vpc_subnets"></a> [vpc\_subnets](#input\_vpc\_subnets) | A map of subnet names to CIDR blocks used within the VPC.<br/>These subnets should be in separate availability zones to enable high availability. | `map(string)` | <pre>{<br/>  "a": "172.32.0.0/20",<br/>  "b": "172.32.16.0/20",<br/>  "c": "172.32.32.0/20"<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_ca_certificate"></a> [cluster\_ca\_certificate](#output\_cluster\_ca\_certificate) | The base64-decoded certificate authority (CA) data used to verify the EKS Kubernetes API server.<br/>Required when establishing secure (TLS) communication with the cluster. |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | The public endpoint of the EKS cluster's Kubernetes API server.<br/>This value is required to configure `kubectl` or other Kubernetes clients to access the cluster. |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | The unique identifier (ID) of the AWS EKS cluster.<br/>Typically used to reference the cluster in scripts or cross-module resources. |
| <a name="output_cluster_token"></a> [cluster\_token](#output\_cluster\_token) | A temporary authentication token used to access the EKS Kubernetes API.<br/>This token is valid for 15 minutes and should be treated as sensitive.<br/>Typically used as a Bearer token in Kubernetes client configuration. |
<!-- END_TF_DOCS -->
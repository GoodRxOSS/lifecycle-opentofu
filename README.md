# OpenTofu Lifecycle Module

This module provides a quick and easy way to launch the Lifecycle application on different cloud providers with support for multiple DNS providers. It is ideal for testing, demos, and learning—**do not use in production**!

---

## 🚀 Features

* **Multi-cloud support**: AWS EKS, GCP GKE, and (coming soon) OpenStack
* **Multi-DNS support**: Cloudflare, AWS Route 53, GCP Cloud DNS
* **Self-contained logic**: No external OpenTofu/Terraform modules—everything is implemented in internal submodules
* **Minimal infrastructure**: Creates just the necessary resources for the Lifecycle app, optimizing cost

---

## 📋 Supported Providers

| Cloud Provider | Module Parameter                 | Status      |
| -------------- | -------------------------------- | ----------- |
| Amazon EKS     | `cluster_provider = "eks"`       | Stable      |
| Google GKE     | `cluster_provider = "gke"`       | Stable      |
| OpenStack      | `cluster_provider = "openstack"` | Coming Soon |

| DNS Provider  | Parameter Key                 | Status |
| ------------- | ----------------------------- | ------ |
| Cloudflare    | `dns_provider = "cloudflare"` | Stable |
| AWS Route 53  | `dns_provider = "route53"`    | Stable |
| GCP Cloud DNS | `dns_provider = "cloud-dns"`  | Stable |

You can mix-and-match, e.g. AWS EKS with Cloudflare DNS or GKE with Route 53.

---

## ⚙️ Prerequisites

1. **OpenTofu CLI** installed and initialized. OpenTofu is an open-source infrastructure-as-code tool and is fully compatible with Terraform v0.13+ syntax.

2. A cloud account for your chosen provider:
   * **AWS**: free tier available
   * **GCP**: free \$300 credit trial
   * **OpenStack**: self-hosted (coming soon)

3. DNS account for your chosen DNS provider:
   * **Cloudflare**: free tier includes 1 zone
   * **Route 53**: pay-as-you-go
   * **Cloud DNS**: pay-as-you-go

---

## 🛠️ Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/GoodRxOSS/lifecycle-opentofu.git
cd opentofu-lifecycle
```

### 2. Configure Cloud CLI

#### AWS EKS

1. Create an IAM user with a programmatic key (for testing only!).
2. Attach **AdministratorAccess** policy (or fine-grained DNS, EKS, VPC permissions).
3. Configure AWS CLI profile:

   ```bash
   aws configure --profile lifecycle-oss-eks
   ```
4. Optional: Create a DNS zone, delegate NS records at your registrar.

#### GCP GKE

1. Create a Google Cloud project and enable the Kubernetes Engine API.
2. Install and authenticate `gcloud` CLI.
3. Get credentials:

   ```bash
   gcloud config set project lifecycle-oss-123456
   gcloud auth application-default login
   ```
4. Optional: Create a DNS zone, delegate NS records at your registrar.

#### Cloudflare DNS

1. Sign up for Cloudflare and add your domain.
2. Create a DNS zone, delegate NS records at your registrar.
3. Create an API token with **Zone.Zone, Zone.DNS\:Edit** permissions.
4. Save the token securely (e.g., in a secret manager).

---

### 3. Copy Example Variables

```bash
cp example.auto.tfvars secrets.auto.tfvars
# Edit secrets.auto.tfvars with your values
```

### 4. Initialize & Apply

```bash
tofu init
tofu plan
tofu apply
```

\* Sometimes, running `tofu apply` once is not enough to fully provision all resources. This can happen due to eventual consistency in cloud APIs or delays in external systems.

   Common reasons why multiple tofu apply runs may be needed:

   1. DNS Propagation — Some cloud resources depend on DNS names that may not resolve immediately after being created. Dependent resources may fail on the first run.

   2. Service Readiness — If a resource (e.g., Load Balancer, DB instance) needs time to become fully ready, another resource depending on it might fail during the same apply.

   3. IAM Permissions Delay — Recently updated roles or policies might not be fully propagated across the provider’s infrastructure.

   4. Rate Limits / API Race Conditions — Some providers impose soft throttling or transient errors during rapid provisioning.

   ✅ Solution: Just run tofu apply again. OpenTofu is designed to pick up from the current state and continue applying remaining changes. No need to worry — this is part of normal behavior when working with eventual-consistency cloud environments.

After running `tofu apply`, you should see a cheatsheet like this:

   - Amazon EKS

      ```shell
      help = <<EOT
      Quick help of usage [eks]:
      - Update `kubeconfig` file:
            $ aws eks update-kubeconfig --name lifecycle-oss --region us-west-2 --profile lifecycle-oss-eks

      - Check cluster permissions, e.g. List Pods in `lifecycle-app` namespace
            $ kubectl -n lifecycle-app get pods

      - Check public endpoint, DNS, certificates etc.
            $ curl -v https://kuard.example.com

      EOT
      ```

   - Google GKE

      ```shell
      help = <<EOT
      Quick help of usage [gke]:
      - Update `kubeconfig` file:
            $ gcloud container clusters get-credentials lifecycle-oss --zone us-central1-b --project lifecycle-oss-123456

      - Check cluster permissions, e.g. List Pods in `lifecycle-app` namespace
            $ kubectl -n lifecycle-app get pods

      - Check public endpoint, DNS, certificates etc.
            $ curl -v https://kuard.example.com

      EOT
      ```

   This is an autogenerated cheatsheet: copy, paste and run 🚀

### 5. Cleaning up

```bash
tofu destroy
```

\* Sometimes, when you run `tofu destroy`, not all resources are removed in a single attempt — and that’s expected in some cases. Network delays, expired credentials, or external system propagation (like DNS or IAM updates) can temporarily block proper cleanup. Just try running `tofu destroy` again after a short wait.

⚠️ Avoid Manual Deletion Unless Absolutely Necessary
Manually deleting resources that were provisioned programmatically (via OpenTofu) is not recommended unless you are fully aware of the consequences.

Before resorting to manual intervention:

1. Run tofu destroy multiple times to give the system time to resolve dependencies and update states.

2. If a resource still cannot be destroyed automatically (due to external constraints or provider API limitations), only then consider manual deletion, and document the action carefully to avoid state drift.

Manually removing resources can lead to:

1. Inconsistent state files

2. Broken dependencies on future deployments

---

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | ~> 5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 6.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.17.0 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | 1.19.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.37.1 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.7.2 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cloud_dns"></a> [cloud\_dns](#module\_cloud\_dns) | ./modules/gcp-cloud-dns | n/a |
| <a name="module_cloudflare"></a> [cloudflare](#module\_cloudflare) | ./modules/cloudflare-dns | n/a |
| <a name="module_eks"></a> [eks](#module\_eks) | ./modules/aws-eks | n/a |
| <a name="module_gke"></a> [gke](#module\_gke) | ./modules/gcp-gke | n/a |
| <a name="module_route53"></a> [route53](#module\_route53) | ./modules/aws-route53 | n/a |

## Resources

| Name | Type |
|------|------|
| [helm_release.app_buildkit](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.app_distribution](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.app_postgres](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.app_redis](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.cert_manager](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.ingress_nginx_controller](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.letsencrypt_clusterissuer](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.letsencrypt_dns_certificate](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.letsencrypt_dns_clusterissuer](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.letsencrypt_dns_credentials_secret](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.wildcard_certificate_secret](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubernetes_config_map_v1.app_config](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map_v1) | resource |
| [kubernetes_deployment.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_ingress_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_v1) | resource |
| [kubernetes_namespace_v1.app](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [kubernetes_secret_v1.app_postgres](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |
| [kubernetes_secret_v1.app_redis](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |
| [kubernetes_service.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |
| [kubernetes_storage_class.aws_gp3](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class) | resource |
| [random_password.app_postgres](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.app_redis](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [kubernetes_service.ingress_nginx_controller](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app_buildkit_enabled"></a> [app\_buildkit\_enabled](#input\_app\_buildkit\_enabled) | Toggle to control whether BuildKit is deployed (e.g., for image builds). | `bool` | `true` | no |
| <a name="input_app_distribution_enabled"></a> [app\_distribution\_enabled](#input\_app\_distribution\_enabled) | Toggle to enable or disable the distribution module (e.g., API, frontend). | `bool` | `true` | no |
| <a name="input_app_distribution_subdomain"></a> [app\_distribution\_subdomain](#input\_app\_distribution\_subdomain) | Subdomain used to expose the distribution module. | `string` | `"distribution"` | no |
| <a name="input_app_domain"></a> [app\_domain](#input\_app\_domain) | n/a | `string` | `"example.com"` | no |
| <a name="input_app_enabled"></a> [app\_enabled](#input\_app\_enabled) | Global toggle to enable or disable the entire application deployment. | `bool` | `true` | no |
| <a name="input_app_namespace"></a> [app\_namespace](#input\_app\_namespace) | n/a | `string` | `"application-env"` | no |
| <a name="input_app_postgres_database"></a> [app\_postgres\_database](#input\_app\_postgres\_database) | Name of the PostgreSQL database to create and use. | `string` | `"lifecycle"` | no |
| <a name="input_app_postgres_enabled"></a> [app\_postgres\_enabled](#input\_app\_postgres\_enabled) | Toggle to control whether PostgreSQL is deployed. | `bool` | `true` | no |
| <a name="input_app_postgres_port"></a> [app\_postgres\_port](#input\_app\_postgres\_port) | Port used to connect to the PostgreSQL service. | `number` | `5432` | no |
| <a name="input_app_postgres_username"></a> [app\_postgres\_username](#input\_app\_postgres\_username) | Username for accessing the PostgreSQL database. | `string` | `"lifecycle"` | no |
| <a name="input_app_redis_enabled"></a> [app\_redis\_enabled](#input\_app\_redis\_enabled) | Toggle to control whether Redis is deployed. | `bool` | `true` | no |
| <a name="input_app_redis_port"></a> [app\_redis\_port](#input\_app\_redis\_port) | Port used to connect to the Redis service. | `number` | `6379` | no |
| <a name="input_app_subdomain"></a> [app\_subdomain](#input\_app\_subdomain) | Subdomain used to expose the Application module. | `string` | `"app"` | no |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | The AWS CLI profile name to use for authentication and authorization<br/>when interacting with AWS services. This profile should be configured<br/>in your AWS credentials file (usually located at ~/.aws/credentials).<br/><br/>The profile name must:<br/>  - Be a non-empty string<br/>  - Contain only alphanumeric characters, underscores (\_), hyphens (-), and dots (.)<br/>  - Start and end with an alphanumeric character<br/><br/>Example valid profile names:<br/>  - default<br/>  - lifecycle-oss-eks<br/>  - my\_profile-1<br/><br/>Note: Make sure the profile exists and has the necessary permissions. | `string` | `"default"` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region where the EKS cluster and related resources will be deployed.<br/>Example: "us-east-1", "eu-west-1", "us-west-2" | `string` | `"us-west-2"` | no |
| <a name="input_cloudflare_api_token"></a> [cloudflare\_api\_token](#input\_cloudflare\_api\_token) | n/a | `string` | `null` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name of the Kubernetes cluster.<br/>Must consist of alphanumeric characters, dashes, and be 1–100 characters long. | `string` | `"k8s-cluster"` | no |
| <a name="input_cluster_provider"></a> [cluster\_provider](#input\_cluster\_provider) | n/a | `string` | `"eks"` | no |
| <a name="input_dns_provider"></a> [dns\_provider](#input\_dns\_provider) | n/a | `string` | `"route53"` | no |
| <a name="input_gcp_credentials_file"></a> [gcp\_credentials\_file](#input\_gcp\_credentials\_file) | n/a | `string` | `null` | no |
| <a name="input_gcp_project"></a> [gcp\_project](#input\_gcp\_project) | The Google Cloud Project ID to use for creating and managing resources.<br/>This should be the unique identifier of your GCP project.<br/>If not provided (null), some modules might attempt to infer the project from<br/>your environment or credentials.<br/><br/>Format requirements:<br/>  - Length between 6 and 30 characters<br/>  - Lowercase letters, digits, and hyphens only<br/>  - Must start with a lowercase letter<br/>  - Cannot end with a hyphen | `string` | `null` | no |
| <a name="input_gcp_region"></a> [gcp\_region](#input\_gcp\_region) | The Google Cloud region or zone where the GKE cluster is deployed.<br/>Example: "us-central1" or "us-central1-b" | `string` | `"us-central1-b"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_help"></a> [help](#output\_help) | Quick help of usage |
<!-- END_TF_DOCS -->

---

## ⚠️ Disclaimer

This module is provided **as-is** for demonstration and testing purposes. **Do not** use it in production environments without proper security review and adaptation.

---

## 🔄 Contributing

Contributions, issues, and feature requests are welcome! Please open an issue or submit a pull request on the GitHub repository.

---

## 📜 License

This project is licensed under the Apache License 2.0. See [LICENSE](./LICENSE) for details.

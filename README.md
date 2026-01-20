# OpenTofu Lifecycle Module

This module provides a quick and easy way to launch the Lifecycle application on different cloud providers with support for multiple DNS providers. It is ideal for testing, demos, and learning—**do not use in production**!

---

## 🚀 Features

- **Multi-cloud support**: AWS EKS, GCP GKE, and OpenStack Magnum
- **Multi-DNS support**: Cloudflare, AWS Route 53, GCP Cloud DNS
- **Self-contained logic**: No external OpenTofu/Terraform modules—everything is implemented in internal submodules
- **Minimal infrastructure**: Creates just the necessary resources for the Lifecycle app, optimizing cost

---

## 📋 Supported Providers

| Cloud Provider   | Module Parameter              | Status |
| ---------------- | ----------------------------- | ------ |
| Amazon EKS       | `cluster_provider = "eks"`    | Stable |
| Google GKE       | `cluster_provider = "gke"`    | Stable |
| OpenStack Magnum | `cluster_provider = "magnum"` | Beta   |

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
   - **AWS**: free tier available
   - **GCP**: free \$300 credit trial
   - **OpenStack**: self-hosted (see [OpenStack Detailed Requirements](#-openstack-detailed-requirements) for setup details)

3. DNS account for your chosen DNS provider:
   - **Cloudflare**: free tier includes 1 zone
   - **Route 53**: pay-as-you-go
   - **Cloud DNS**: pay-as-you-go

---

## 🏗️ OpenStack Detailed Requirements

> [!WARNING]
> Using this module with OpenStack requires advanced knowledge of OpenStack administration. Many environment-specific nuances (networking, storage backends, security groups) are not covered by this setup. It is assumed the user is an experienced administrator or has access to a correctly pre-configured environment.

### 🧩 Required Components

Your OpenStack environment must have the following services enabled and functional:

| Service       | Component       | Purpose                                       |
| ------------- | --------------- | --------------------------------------------- |
| **Keystone**  | Identity        | Authentication and service catalog            |
| **Nova**      | Compute         | Provisioning worker and master nodes          |
| **Neutron**   | Network         | Managing SDN, subnets, and security groups    |
| **Glance**    | Image           | Storing Fedora CoreOS images                  |
| **Cinder/v3** | Volume          | Persistent storage for Kubernetes PVs         |
| **Heat**      | Orchestration   | Magnum uses Heat templates to deploy clusters |
| **Barbican**  | Key Manager     | Certificate and secret management for Magnum  |
| **Octavia**   | Load Balancer   | Handling K8s API and Service LoadBalancers    |
| **Magnum**    | Container Infra | The core service for K8s lifecycle management |

### 🛠️ Identity & Permissions Setup

To run this module, you need a dedicated project and a user with specific roles. Notably, **Barbican** requires the `creator` role to allow Magnum to manage certificates.

**Example Setup Commands:**

```bash
# 1. Create Project and User
openstack project create --domain default lifecycle-project
openstack user create --domain default --project lifecycle-project --password YOUR_PASS lifecycle-user

# 2. Assign Basic Roles
openstack role add --project lifecycle-project --user lifecycle-user member

# 3. Assign Barbican (Key Manager) Roles
# This is CRITICAL for Magnum to store cluster certificates
openstack role add --project lifecycle-project --user lifecycle-user creator

```

### 🖥️ Resource Requirements

#### Flavors

The following flavors must be created in your system:

| Name          | Specs                | Usage                                        |
| ------------- | -------------------- | -------------------------------------------- |
| **m1.small**  | 1 vCPU, 2.00 GiB RAM | Small worker nodes / Testing                 |
| **m1.medium** | 2 vCPU, 4.00 GiB RAM | Master nodes / Standard workers              |
| **amphora**   | _System specific_    | Required for Octavia Load Balancer instances |

#### Images

The cluster is configured to use **Kubernetes v1.32.5**.

- **Requirement**: You must pre-upload the **Fedora-CoreOS-41** image to Glance.
- Ensure the image has the property `os_distro='fedora-coreos'`, as Magnum uses this to identify the bootstrap logic.

### 🧪 Verified Environment

This configuration has been tested on an OpenStack environment deployed via **Kolla-Ansible** with the following parameters:

- **OpenStack Release**: `2025.1` (Epoxy)
- **Base Distro**: `rocky`
- **Network**: Neutron ML2/OVS `(neutron_plugin_agent: "openvswitch")`
- **Storage**: Cinder with LVM/Ceph backend

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

#### OpenStack Magnum

1. **Identity Setup**: Ensure you have a Project, User, and the necessary roles (see below).
2. **Environment Variables**: OpenStack provider uses standard credentials. You must define the following variable in your `secrets.auto.tfvars`:

```hcl
openstack_auth = {
  user_name = "your-username"
  password  = "your-password"
  auth_url  = "https://your-openstack-auth-url:5000/v3"
}
```

3. **CLI Authentication**: Source your OpenStack RC file or ensure your environment is configured to interact with the API:

```bash
export OS_CLOUD=lifecycle-project
# or
source project-openrc.sh
```

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

1.  DNS Propagation — Some cloud resources depend on DNS names that may not resolve immediately after being created. Dependent resources may fail on the first run.

2.  Service Readiness — If a resource (e.g., Load Balancer, DB instance) needs time to become fully ready, another resource depending on it might fail during the same apply.

3.  IAM Permissions Delay — Recently updated roles or policies might not be fully propagated across the provider’s infrastructure.

4.  Rate Limits / API Race Conditions — Some providers impose soft throttling or transient errors during rapid provisioning.

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

- Openstack Magnum

  ```shell
  help = <<EOT
  Quick help of usage [magnum]:
  - Update `kubeconfig` file:
        $ tofu output -raw kubeconfig > ~/.kube/config-magnum-lfc && export KUBECONFIG=~/.kube/config:$HOME/.kube/config-magnum-lfc && kubectl config view --flatten > ~/.kube/config_temp && mv ~/.kube/config_temp ~/.kube/config && rm ~/.kube/config-magnum-lfc

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

| Name                                                                        | Version |
| --------------------------------------------------------------------------- | ------- |
| <a name="requirement_aws"></a> [aws](#requirement_aws)                      | ~> 5.0  |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement_cloudflare) | ~> 5.0  |
| <a name="requirement_google"></a> [google](#requirement_google)             | ~> 6.0  |
| <a name="requirement_helm"></a> [helm](#requirement_helm)                   | ~> 2.0  |
| <a name="requirement_kubectl"></a> [kubectl](#requirement_kubectl)          | ~> 1.0  |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement_kubernetes) | ~> 2.0  |
| <a name="requirement_openstack"></a> [openstack](#requirement_openstack)    | ~> 3.0  |
| <a name="requirement_random"></a> [random](#requirement_random)             | ~> 3.0  |
| <a name="requirement_tls"></a> [tls](#requirement_tls)                      | ~> 4.0  |

## Providers

| Name                                                                  | Version |
| --------------------------------------------------------------------- | ------- |
| <a name="provider_cloudflare"></a> [cloudflare](#provider_cloudflare) | 5.12.0  |
| <a name="provider_helm"></a> [helm](#provider_helm)                   | 2.17.0  |
| <a name="provider_kubectl"></a> [kubectl](#provider_kubectl)          | 1.19.0  |
| <a name="provider_kubernetes"></a> [kubernetes](#provider_kubernetes) | 2.38.0  |
| <a name="provider_random"></a> [random](#provider_random)             | 3.7.2   |
| <a name="provider_time"></a> [time](#provider_time)                   | 0.13.1  |

## Modules

| Name                                                                                   | Source                     | Version |
| -------------------------------------------------------------------------------------- | -------------------------- | ------- |
| <a name="module_cloud_dns"></a> [cloud_dns](#module_cloud_dns)                         | ./modules/gcp-cloud-dns    | n/a     |
| <a name="module_cloudflare"></a> [cloudflare](#module_cloudflare)                      | ./modules/cloudflare-dns   | n/a     |
| <a name="module_cloudflare_tunnel"></a> [cloudflare_tunnel](#module_cloudflare_tunnel) | ./modules/cloudflare-dns   | n/a     |
| <a name="module_eks"></a> [eks](#module_eks)                                           | ./modules/aws-eks          | n/a     |
| <a name="module_gke"></a> [gke](#module_gke)                                           | ./modules/gcp-gke          | n/a     |
| <a name="module_magnum"></a> [magnum](#module_magnum)                                  | ./modules/openstack-magnum | n/a     |
| <a name="module_route53"></a> [route53](#module_route53)                               | ./modules/aws-route53      | n/a     |

## Resources

| Name                                                                                                                                                               | Type        |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------- |
| [cloudflare_zero_trust_tunnel_cloudflared.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_tunnel_cloudflared) | resource    |
| [helm_release.app_buildkit](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release)                                                  | resource    |
| [helm_release.app_distribution](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release)                                              | resource    |
| [helm_release.app_lifecycle](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release)                                                 | resource    |
| [helm_release.app_lifecycle_keycloak](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release)                                        | resource    |
| [helm_release.app_redis](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release)                                                     | resource    |
| [helm_release.cert_manager](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release)                                                  | resource    |
| [helm_release.cloudflare_tunnel](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release)                                             | resource    |
| [helm_release.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release)                                            | resource    |
| [helm_release.external_secrets](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release)                                              | resource    |
| [helm_release.ingress_nginx_controller](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release)                                      | resource    |
| [helm_release.keycloak_operator](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release)                                             | resource    |
| [helm_release.lifecycle_ui](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release)                                                  | resource    |
| [helm_release.postgres_keycloak](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release)                                             | resource    |
| [helm_release.postgres_lifecycle](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release)                                            | resource    |
| [kubectl_manifest.letsencrypt_clusterissuer](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest)                           | resource    |
| [kubectl_manifest.letsencrypt_dns_certificate](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest)                         | resource    |
| [kubectl_manifest.letsencrypt_dns_clusterissuer](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest)                       | resource    |
| [kubectl_manifest.letsencrypt_dns_credentials_secret](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest)                  | resource    |
| [kubectl_manifest.wildcard_certificate_secret](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest)                         | resource    |
| [kubernetes_deployment.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment)                                        | resource    |
| [kubernetes_ingress_v1.cloudflare_tunnel](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_v1)                           | resource    |
| [kubernetes_ingress_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_v1)                                        | resource    |
| [kubernetes_namespace_v1.app](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1)                                     | resource    |
| [kubernetes_secret.image_pull_secret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret)                                   | resource    |
| [kubernetes_secret_v1.app_redis](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1)                                     | resource    |
| [kubernetes_service.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service)                                              | resource    |
| [kubernetes_storage_class.aws_gp3](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class)                               | resource    |
| [kubernetes_storage_class.openstack_ssd](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class)                         | resource    |
| [random_password.app_redis](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password)                                               | resource    |
| [random_password.cloudflare_tunnel](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password)                                       | resource    |
| [time_sleep.ingress_nginx_controller](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep)                                          | resource    |
| [cloudflare_zone.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/data-sources/zone)                                                | data source |
| [kubernetes_service.ingress_nginx_controller](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service)                       | data source |

## Inputs

| Name                                                                                                               | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | Type                                                                                                                                               | Default                                                                                 | Required |
| ------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- | :------: |
| <a name="input_app_buildkit_enabled"></a> [app_buildkit_enabled](#input_app_buildkit_enabled)                      | Toggle to control whether BuildKit is deployed (e.g., for image builds).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            | `bool`                                                                                                                                             | `false`                                                                                 |    no    |
| <a name="input_app_distribution_enabled"></a> [app_distribution_enabled](#input_app_distribution_enabled)          | Toggle to enable or disable the distribution module (e.g., API, frontend).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | `bool`                                                                                                                                             | `false`                                                                                 |    no    |
| <a name="input_app_distribution_subdomain"></a> [app_distribution_subdomain](#input_app_distribution_subdomain)    | Subdomain used to expose the distribution module.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | `string`                                                                                                                                           | `"distribution"`                                                                        |    no    |
| <a name="input_app_domain"></a> [app_domain](#input_app_domain)                                                    | n/a                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | `string`                                                                                                                                           | `"example.com"`                                                                         |    no    |
| <a name="input_app_enabled"></a> [app_enabled](#input_app_enabled)                                                 | Global toggle to enable or disable the entire application deployment.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               | `bool`                                                                                                                                             | `true`                                                                                  |    no    |
| <a name="input_app_lifecycle_enabled"></a> [app_lifecycle_enabled](#input_app_lifecycle_enabled)                   | Toggle to control whether PostgreSQL is deployed.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | `bool`                                                                                                                                             | `true`                                                                                  |    no    |
| <a name="input_app_lifecycle_keycloak"></a> [app_lifecycle_keycloak](#input_app_lifecycle_keycloak)                | Toggle to control whether Keycloak instance for Lifecycle is deployed.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              | `bool`                                                                                                                                             | `false`                                                                                 |    no    |
| <a name="input_app_lifecycle_secrets"></a> [app_lifecycle_secrets](#input_app_lifecycle_secrets)                   | Map of custom secrets and configurations to be merged into the app-lifecycle <br/>Helm release values. Allows manual provisioning of the 'secrets' block during <br/>bootstrap (e.g., using existing GitHub Application secrets).<br/>WARNING: Not recommended for production use. Primarily intended for development <br/>and initial bootstrapping.                                                                                                                                                                                                                                                               | `any`                                                                                                                                              | `{}`                                                                                    |    no    |
| <a name="input_app_lifecycle_ui"></a> [app_lifecycle_ui](#input_app_lifecycle_ui)                                  | Toggle to control whether Lifecycle UI is deployed.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | `bool`                                                                                                                                             | `false`                                                                                 |    no    |
| <a name="input_app_namespace"></a> [app_namespace](#input_app_namespace)                                           | n/a                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | `string`                                                                                                                                           | `"application-env"`                                                                     |    no    |
| <a name="input_app_redis_enabled"></a> [app_redis_enabled](#input_app_redis_enabled)                               | Toggle to control whether Redis is deployed.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | `bool`                                                                                                                                             | `false`                                                                                 |    no    |
| <a name="input_app_redis_port"></a> [app_redis_port](#input_app_redis_port)                                        | Port used to connect to the Redis service.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | `number`                                                                                                                                           | `6379`                                                                                  |    no    |
| <a name="input_app_subdomain"></a> [app_subdomain](#input_app_subdomain)                                           | Subdomain used to expose the Application module.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    | `string`                                                                                                                                           | `"app"`                                                                                 |    no    |
| <a name="input_aws_profile"></a> [aws_profile](#input_aws_profile)                                                 | The AWS CLI profile name to use for authentication and authorization<br/>when interacting with AWS services. This profile should be configured<br/>in your AWS credentials file (usually located at ~/.aws/credentials).<br/><br/>The profile name must:<br/> - Be a non-empty string<br/> - Contain only alphanumeric characters, underscores (\_), hyphens (-), and dots (.)<br/> - Start and end with an alphanumeric character<br/><br/>Example valid profile names:<br/> - default<br/> - lifecycle-oss-eks<br/> - my_profile-1<br/><br/>Note: Make sure the profile exists and has the necessary permissions. | `string`                                                                                                                                           | `"default"`                                                                             |    no    |
| <a name="input_aws_region"></a> [aws_region](#input_aws_region)                                                    | The AWS region where the EKS cluster and related resources will be deployed.<br/>Example: "us-east-1", "eu-west-1", "us-west-2"                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     | `string`                                                                                                                                           | `"us-west-2"`                                                                           |    no    |
| <a name="input_cloudflare_api_token"></a> [cloudflare_api_token](#input_cloudflare_api_token)                      | n/a                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | `string`                                                                                                                                           | `null`                                                                                  |    no    |
| <a name="input_cloudflare_tunnel_domain"></a> [cloudflare_tunnel_domain](#input_cloudflare_tunnel_domain)          | The domain name for the tunnel's ingress rules.<br/>If null, 'var.app_domain' will be used as a fallback.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | `string`                                                                                                                                           | `null`                                                                                  |    no    |
| <a name="input_cloudflare_tunnel_enabled"></a> [cloudflare_tunnel_enabled](#input_cloudflare_tunnel_enabled)       | Controls whether to create and deploy the Cloudflare Tunnel resources.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              | `bool`                                                                                                                                             | `false`                                                                                 |    no    |
| <a name="input_cloudflare_tunnel_name"></a> [cloudflare_tunnel_name](#input_cloudflare_tunnel_name)                | The display name of the Cloudflare Tunnel.<br/>Used to identify the tunnel in the Zero Trust dashboard.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | `string`                                                                                                                                           | `"lifecycle"`                                                                           |    no    |
| <a name="input_cluster_name"></a> [cluster_name](#input_cluster_name)                                              | The name of the Kubernetes cluster.<br/>Must consist of alphanumeric characters, dashes, and be 1–100 characters long.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              | `string`                                                                                                                                           | `"k8s-cluster"`                                                                         |    no    |
| <a name="input_cluster_provider"></a> [cluster_provider](#input_cluster_provider)                                  | n/a                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | `string`                                                                                                                                           | `"eks"`                                                                                 |    no    |
| <a name="input_dns_provider"></a> [dns_provider](#input_dns_provider)                                              | n/a                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | `string`                                                                                                                                           | `"route53"`                                                                             |    no    |
| <a name="input_external_database_enabled"></a> [external_database_enabled](#input_external_database_enabled)       | If set to true, the module switches to 'External Database' mode. <br/>This disables internal database provisioning within the main Helm chart and <br/>instead uses separate, independently managed Helm charts for PostgreSQL <br/>(lifecycle and keycloak).                                                                                                                                                                                                                                                                                                                                                       | `bool`                                                                                                                                             | `false`                                                                                 |    no    |
| <a name="input_gcp_credentials_file"></a> [gcp_credentials_file](#input_gcp_credentials_file)                      | n/a                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | `string`                                                                                                                                           | `null`                                                                                  |    no    |
| <a name="input_gcp_project"></a> [gcp_project](#input_gcp_project)                                                 | The Google Cloud Project ID to use for creating and managing resources.<br/>This should be the unique identifier of your GCP project.<br/>If not provided (null), some modules might attempt to infer the project from<br/>your environment or credentials.<br/><br/>Format requirements:<br/> - Length between 6 and 30 characters<br/> - Lowercase letters, digits, and hyphens only<br/> - Must start with a lowercase letter<br/> - Cannot end with a hyphen                                                                                                                                                    | `string`                                                                                                                                           | `null`                                                                                  |    no    |
| <a name="input_gcp_region"></a> [gcp_region](#input_gcp_region)                                                    | The Google Cloud region or zone where the GKE cluster is deployed.<br/>Example: "us-central1" or "us-central1-b"                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    | `string`                                                                                                                                           | `"us-central1-b"`                                                                       |    no    |
| <a name="input_keycloak_operator_enabled"></a> [keycloak_operator_enabled](#input_keycloak_operator_enabled)       | Toggle to control whether Keycloak Operator is deployed.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            | `bool`                                                                                                                                             | `true`                                                                                  |    no    |
| <a name="input_openstack_auth"></a> [openstack_auth](#input_openstack_auth)                                        | OpenStack authentication credentials. <br/>Includes user_name, password, and auth_url.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              | <pre>object({<br/> user_name = optional(string)<br/> password = optional(string)<br/> auth_url = optional(string)<br/> })</pre>                    | <pre>{<br/> "auth_url": null,<br/> "password": null,<br/> "user_name": null<br/>}</pre> |    no    |
| <a name="input_openstack_project"></a> [openstack_project](#input_openstack_project)                               | The name of the OpenStack project (tenant). <br/>Must be URL-safe and follow corporate naming conventions.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | `string`                                                                                                                                           | `null`                                                                                  |    no    |
| <a name="input_openstack_region"></a> [openstack_region](#input_openstack_region)                                  | The name of the OpenStack region. Standard default is RegionOne.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    | `string`                                                                                                                                           | `"RegionOne"`                                                                           |    no    |
| <a name="input_pbkdf2_passphrase"></a> [pbkdf2_passphrase](#input_pbkdf2_passphrase)                               | n/a                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | `string`                                                                                                                                           | n/a                                                                                     |   yes    |
| <a name="input_postgres_keycloak_database"></a> [postgres_keycloak_database](#input_postgres_keycloak_database)    | Name of the PostgreSQL Keycloak database to create and use.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | `string`                                                                                                                                           | `"keycloak"`                                                                            |    no    |
| <a name="input_postgres_keycloak_enabled"></a> [postgres_keycloak_enabled](#input_postgres_keycloak_enabled)       | Toggle to control whether PostgreSQL Keycloak is deployed.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | `bool`                                                                                                                                             | `false`                                                                                 |    no    |
| <a name="input_postgres_keycloak_port"></a> [postgres_keycloak_port](#input_postgres_keycloak_port)                | Port used to connect to the PostgreSQL Keycloak service.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            | `number`                                                                                                                                           | `5432`                                                                                  |    no    |
| <a name="input_postgres_keycloak_username"></a> [postgres_keycloak_username](#input_postgres_keycloak_username)    | Username for accessing the Keycloak Lifecycle database.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | `string`                                                                                                                                           | `"keycloak"`                                                                            |    no    |
| <a name="input_postgres_lifecycle_database"></a> [postgres_lifecycle_database](#input_postgres_lifecycle_database) | Name of the PostgreSQL Lifecycle database to create and use.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | `string`                                                                                                                                           | `"lifecycle"`                                                                           |    no    |
| <a name="input_postgres_lifecycle_enabled"></a> [postgres_lifecycle_enabled](#input_postgres_lifecycle_enabled)    | Toggle to control whether PostgreSQL Lifecycle is deployed.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | `bool`                                                                                                                                             | `false`                                                                                 |    no    |
| <a name="input_postgres_lifecycle_port"></a> [postgres_lifecycle_port](#input_postgres_lifecycle_port)             | Port used to connect to the PostgreSQL Lifecycle service.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | `number`                                                                                                                                           | `5432`                                                                                  |    no    |
| <a name="input_postgres_lifecycle_username"></a> [postgres_lifecycle_username](#input_postgres_lifecycle_username) | Username for accessing the PostgreSQL Lifecycle database.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | `string`                                                                                                                                           | `"lifecycle"`                                                                           |    no    |
| <a name="input_private_registries"></a> [private_registries](#input_private_registries)                            | Configuration for private registries (Helm charts and Container images).<br/>If empty, no registry blocks will be created.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | <pre>list(object({<br/> url = string<br/> username = string<br/> password = string<br/> usage = list(string) # ["charts", "images"]<br/> }))</pre> | `[]`                                                                                    |    no    |
| <a name="input_ssh_public_key"></a> [ssh_public_key](#input_ssh_public_key)                                        | The content of the SSH public key (e.g., contents of ~/.ssh/id_rsa.pub). <br/>Supports RSA, ECDSA, and ED25519 formats.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | `string`                                                                                                                                           | `null`                                                                                  |    no    |
| <a name="input_ssh_public_key_path"></a> [ssh_public_key_path](#input_ssh_public_key_path)                         | The local filesystem path to the SSH public key file.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               | `string`                                                                                                                                           | `"~/.ssh/id_rsa.pub"`                                                                   |    no    |

## Outputs

| Name                                                              | Description                                                                                                                                                                                                                                                                                                                                                      |
| ----------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| <a name="output_help"></a> [help](#output_help)                   | Quick help of usage                                                                                                                                                                                                                                                                                                                                              |
| <a name="output_kubeconfig"></a> [kubeconfig](#output_kubeconfig) | The Kubernetes configuration file (kubeconfig) for the Magnum cluster.<br/>This configuration is primarily generated based on the client certificates, <br/>private keys, and CA data provided by the OpenStack Magnum API.<br/>It provides 'kubectl' with the necessary credentials to authenticate <br/>and manage the cluster with administrative privileges. |

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

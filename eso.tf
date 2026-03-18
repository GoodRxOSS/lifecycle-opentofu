# Copyright 2026 GoodRx, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

resource "helm_release" "external_secrets" {
  count = var.external_secrets_enabled ? 1 : 0

  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = var.external_secrets_chart_version
  namespace        = var.external_secrets_namespace
  create_namespace = true

  values = [
    yamlencode({
      serviceAccount = {
        annotations = (
          local.is_eks ? {
            "eks.amazonaws.com/role-arn" = one(module.eks[*].eso_role_arn)
          } :
          local.is_gke ? {
            "iam.gke.io/gcp-service-account" = one(module.gke[*].eso_service_account_email)
          } :
          {}
        )
      }
    })
  ]

  depends_on = [
    module.eks,
    module.gke
  ]
}

# ClusterSecretStore for EKS
resource "kubectl_manifest" "cluster_secret_store_eks" {
  count = var.external_secrets_enabled && local.is_eks ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = "aws-secretsmanager"
    }
    spec = {
      provider = {
        aws = {
          service = "SecretsManager"
          region  = var.aws_region
          auth = {
            jwt = {
              serviceAccountRef = {
                name      = "external-secrets"
                namespace = var.external_secrets_namespace
              }
            }
          }
        }
      }
    }
  })

  depends_on = [
    helm_release.external_secrets,
  ]
}

# ClusterSecretStore for GKE
resource "kubectl_manifest" "cluster_secret_store_gke" {
  count = var.external_secrets_enabled && local.is_gke ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = "gcp-secretsmanager"
    }
    spec = {
      provider = {
        gcpsm = {
          projectID = var.gcp_project
          auth = {
            workloadIdentity = {
              clusterLocation  = var.gcp_region
              clusterName      = var.cluster_name
              clusterProjectID = var.gcp_project
              serviceAccountRef = {
                name      = "external-secrets"
                namespace = var.external_secrets_namespace
              }
            }
          }
        }
      }
    }
  })

  depends_on = [
    helm_release.external_secrets,
  ]
}

# ClusterSecretStore for Magnum
resource "kubernetes_secret_v1" "cluster_secret_store_magnum" {
  count = var.external_secrets_enabled && local.is_magnum ? 1 : 0

  metadata {
    name      = "barbican-secret"
    namespace = var.external_secrets_namespace
  }

  data = {
    username = var.openstack_auth.user_name
    password = var.openstack_auth.password

    application_credential_id     = one(module.magnum[*].eso_application_credentials.id)
    application_credential_secret = one(module.magnum[*].eso_application_credentials.secret)
  }
}

resource "kubectl_manifest" "cluster_secret_store_magnum" {
  count = var.external_secrets_enabled && local.is_magnum ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1"
    kind       = "ClusterSecretStore"
    metadata = {
      name      = "barbican-secretsmanager"
      namespace = var.external_secrets_namespace
    }
    spec = {
      provider = {
        barbican = {
          authURL    = var.openstack_auth.auth_url
          tenantName = var.openstack_project
          domainName = "default"
          region     = var.openstack_region
          auth = {
            username = {
              secretRef = {
                name      = one(kubernetes_secret_v1.cluster_secret_store_magnum[*].metadata[0].name)
                key       = "username"
                namespace = var.external_secrets_namespace
              }
            }
            password = {
              secretRef = {
                name      = one(kubernetes_secret_v1.cluster_secret_store_magnum[*].metadata[0].name)
                key       = "password"
                namespace = var.external_secrets_namespace
              }
            }
          }
        }
      }
    }
  })

  depends_on = [
    helm_release.external_secrets,
    kubernetes_secret_v1.cluster_secret_store_magnum,
  ]
}

# Copyright 2025 GoodRx, Inc.
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

# Main cluster bootstrap steps

resource "helm_release" "cluster_autoscaler" {
  count = var.cluster_provider == "gke" ? 1 : 0

  name             = "cluster-autoscaler"
  repository       = "https://kubernetes.github.io/autoscaler"
  chart            = "cluster-autoscaler"
  namespace        = "kube-system"
  version          = "9.46.6"
  create_namespace = false

  values = [
    yamlencode({
      cloudProvider = (
        var.cluster_provider == "gke" ? "gce" :
        var.cluster_provider == "eks" ? "aws" :
        "clusterapi"
      )
      autoDiscovery = {
        clusterName = local.cluster.name
      }
      rbac = {
        create = true
      }
      extraArgs = {
        "balance-similar-node-groups"   = "true"
        "skip-nodes-with-local-storage" = "false"
        "expander"                      = "least-waste"
      }
      extraEnv = var.cluster_provider == "eks" ? {
        "AWS_REGION" = var.aws_region
      } : {}
    })
  ]
}

resource "helm_release" "ingress_nginx_controller" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  version          = "4.12.2"
  create_namespace = true

  values = [
    yamlencode({
      controller = {
        allowSnippetAnnotations = true
        extraArgs = {
          default-ssl-certificate = format("%s/wildcard.%s", var.app_namespace, var.app_domain)
        }
        config = {
          annotations-risk-level  = "Critical"
          proxy-buffer-size       = "16k"
          proxy-buffers-number    = "8"
          proxy-busy-buffers-size = "32k"
        }
        publishService = {
          enabled = true
        }
      }
    })
  ]
}

data "kubernetes_service" "ingress_nginx_controller" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = helm_release.ingress_nginx_controller.namespace
  }

  depends_on = [
    helm_release.ingress_nginx_controller
  ]
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  version          = "1.17.2"
  create_namespace = true

  values = [
    yamlencode({
      installCRDs = true
    })
  ]
}

resource "kubectl_manifest" "letsencrypt_clusterissuer" {
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt"
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = format("acme@%s", var.app_domain)
        privateKeySecretRef = {
          name = "letsencrypt"
        }
        solvers = [
          {
            http01 = {
              ingress = {
                class = "nginx"
              }
            }
          }
        ]
      }
    }
  })

  depends_on = [
    helm_release.cert_manager
  ]
}


resource "kubectl_manifest" "letsencrypt_dns_credentials_secret" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name      = "letsencrypt-dns-credentials"
      namespace = "cert-manager"
    }
    type = "Opaque"
    stringData = (
      var.dns_provider == "route53" ? {
        AWS_ACCESS_KEY_ID     = one(module.route53[*].aws_access_key_id)
        AWS_SECRET_ACCESS_KEY = one(module.route53[*].aws_secret_access_key)
      } :
      var.dns_provider == "cloudflare" ? {
        cloudflare-api-token = var.cloudflare_api_token
      } :
    {})
    data = (
      var.dns_provider == "cloud-dns" ? {
        gcp-service-account-key = one(module.cloud_dns[*].gcp_service_account_key)
      } :
    {})
  })

  depends_on = [
    helm_release.cert_manager,
  ]
}

resource "kubectl_manifest" "letsencrypt_dns_clusterissuer" {
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-dns"
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = format("acme@%s", var.app_domain)
        privateKeySecretRef = {
          name = "letsencrypt-dns-key"
        }
        solvers = [
          merge(
            var.dns_provider == "route53" ? {
              dns01 = {
                route53 = {
                  region       = var.aws_region
                  hostedZoneID = one(module.route53[*].route53_zone_id)
                  accessKeyID  = one(module.route53[*].aws_access_key_id)
                  secretAccessKeySecretRef = {
                    name = "letsencrypt-dns-credentials"
                    key  = "AWS_SECRET_ACCESS_KEY"
                  }
                }
              }
            } : {},
            var.dns_provider == "cloud-dns" ? {
              dns01 = {
                cloudDNS = {
                  project = var.gcp_project
                  serviceAccountSecretRef = {
                    name = "letsencrypt-dns-credentials"
                    key  = "gcp-service-account-key"
                  }
                }
              }
            } : {},
            var.dns_provider == "cloudflare" ? {
              dns01 = {
                cloudflare = {
                  email = format("acme@0%s", var.app_domain)
                  apiTokenSecretRef = {
                    name = "letsencrypt-dns-credentials"
                    key  = "cloudflare-api-token"
                  }
                }
              }
            } : {}
          )
        ]
      }
    }
  })
  depends_on = [
    kubectl_manifest.letsencrypt_dns_credentials_secret,
  ]
}

resource "kubectl_manifest" "wildcard_certificate_secret" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name      = format("wildcard.%s", var.app_domain)
      namespace = kubernetes_namespace_v1.app.metadata[0].name
    }
    type = "Opaque"
  })

  depends_on = [
    helm_release.cert_manager,
  ]
}

resource "kubectl_manifest" "letsencrypt_dns_certificate" {
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = format("wildcard.%s", var.app_domain)
      namespace = kubernetes_namespace_v1.app.metadata[0].name
    }
    spec = {
      secretName = format("wildcard.%s", var.app_domain)
      issuerRef = {
        name = "letsencrypt-dns"
        kind = "ClusterIssuer"
      }
      commonName = format("*.%s", var.app_domain)
      dnsNames = [
        format("*.%s", var.app_domain),
        var.app_domain,
      ]
    }
  })

  depends_on = [
    helm_release.cert_manager,
    kubectl_manifest.letsencrypt_dns_credentials_secret,
    kubectl_manifest.letsencrypt_dns_clusterissuer,
  ]
}

resource "helm_release" "keycloak_operator" {
  count = var.keycloak_operator_enabled ? 1 : 0

  name             = "keycloak-operator"
  repository       = "oci://ghcr.io/goodrxoss/helm-charts"
  chart            = "keycloak-operator"
  version          = "0.1.0"
  namespace        = "keycloak"
  create_namespace = true

  values = [
    yamlencode({
      watchNamespaces = [
        "keycloak",
        kubernetes_namespace_v1.app.metadata[0].name,
      ]
    })
  ]

  depends_on = [
    kubernetes_namespace_v1.app
  ]
}

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

# App-related Helm charts, Kubernetes manifests, etc.

resource "kubernetes_namespace_v1" "app" {
  metadata {
    name = var.app_namespace
  }
}

resource "random_password" "app_postgres" {
  count = var.app_postgres_enabled ? 1 : 0

  length  = 40
  special = false
}

resource "random_password" "app_redis" {
  count = var.app_redis_enabled ? 1 : 0

  length  = 40
  special = false
}

resource "time_sleep" "ingress_nginx_controller" {
  depends_on = [
    helm_release.ingress_nginx_controller
  ]

  create_duration = "60s"
}

resource "kubernetes_secret" "image_pull_secret" {
  count = length([
    for v in var.private_registries : v if contains(v.usage, "images")
  ]) > 0 ? 1 : 0

  type = "kubernetes.io/dockerconfigjson"
  metadata {
    name      = "image-pull-secret"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
  }

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        for v in var.private_registries :
        v.url => {
          auth = base64encode(format("%s:%s", v.username, v.password))
        } if contains(v.usage, "images")
      }
    })
  }

  depends_on = [
    kubernetes_namespace_v1.app,
  ]
}

resource "helm_release" "app_lifecycle" {
  count = var.app_lifecycle_enabled ? 1 : 0

  name             = "lifecycle"
  repository       = "oci://ghcr.io/goodrxoss/helm-charts"
  chart            = "lifecycle"
  version          = "0.3.3"
  namespace        = kubernetes_namespace_v1.app.metadata[0].name
  create_namespace = false

  dynamic "set" {
    for_each = kubernetes_secret.image_pull_secret
    content {
      name  = "global.imagePullSecrets[0].name"
      value = set.value.metadata[0].name
    }
  }

  values = [
    yamlencode({
      global = {
        domain = var.app_domain
        image = {
          tag = "0.1.9"
        }
      }
      components = {
        web = {
          deployment = {
            extraEnv = concat(
              [
                {
                  name  = "LIFECYCLE_MODE"
                  value = "web"
                },
                { # CORS
                  name  = "ALLOWED_ORIGINS"
                  value = format("https://ui.%s", var.app_domain)
                },
              ],
              var.app_lifecycle_keycloak ? [
                {
                  name  = "KEYCLOAK_ISSUER"
                  value = format("https://keycloak.%s/realms/lifecycle", var.app_domain)
                },
                {
                  name  = "KEYCLOAK_CLIENT_ID"
                  value = "lifecycle-core"
                },
                {
                  name = "KEYCLOAK_JWKS_URL"
                  value = format("http://lifecycle-keycloak-service.%s.svc.cluster.local:8080/realms/lifecycle/protocol/openid-connect/certs",
                    kubernetes_namespace_v1.app.metadata[0].name,
                  )
                }
              ] : []
            )
          }
        }
      }
      buildkit = {
        buildkitdToml = <<-EOT
          debug = true
          [registry."lifecycle-distribution.${kubernetes_namespace_v1.app.metadata[0].name}.svc.cluster.local"]
            http = true
            insecure = true
          [worker.oci]
            platforms = [ "linux/amd64" ]
            reservedSpace = "60%"
            maxUsedSpace = "80%"
            max-parallelism = 25
      EOT
      }
      distribution = {
        ingress = {
          hostname = format("%s.%s", var.app_distribution_subdomain, var.app_domain)
        }
      }
    })
  ]

  depends_on = [
    kubernetes_namespace_v1.app,
    time_sleep.ingress_nginx_controller,
  ]
}

resource "helm_release" "app_postgres" {
  count = var.app_postgres_enabled ? 1 : 0

  name             = "postgres"
  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "postgresql"
  version          = "15.5.19"
  namespace        = kubernetes_namespace_v1.app.metadata[0].name
  create_namespace = false

  values = [
    yamlencode({
      fullnameOverride = "postgres"
      auth = {
        enabled  = true
        database = var.app_postgres_database
        username = var.app_postgres_username
        password = one(random_password.app_postgres[*].result)
      }
      primary = {
        persistence = {
          enabled = true
          size    = "11Gi"
        }
      }
    })
  ]

  depends_on = [
    kubernetes_namespace_v1.app
  ]
}

resource "helm_release" "app_redis" {
  count = var.app_redis_enabled ? 1 : 0

  name             = "redis"
  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "redis"
  version          = "19.6.3"
  namespace        = kubernetes_namespace_v1.app.metadata[0].name
  create_namespace = false

  values = [
    yamlencode({
      fullnameOverride = "redis"
      architecture     = "standalone"
      auth = {
        enabled  = true
        password = one(random_password.app_redis[*].result)
      }
      master = {
        persistence = {
          enabled = true
          size    = "8Gi"
        }
      }
    })
  ]

  depends_on = [
    kubernetes_namespace_v1.app
  ]
}

resource "helm_release" "app_distribution" {
  count = var.app_distribution_enabled ? 1 : 0

  name             = "distribution"
  repository       = "https://jouve.github.io/charts/"
  chart            = "distribution"
  version          = "0.1.7"
  namespace        = kubernetes_namespace_v1.app.metadata[0].name
  create_namespace = false

  values = [
    yamlencode({
      image = {
        tag = "2.8.3"
      }
      persistence = {
        enabled = true
        size    = "20Gi"
      }
      ingress = {
        enabled          = true
        hostname         = format("%s.%s", var.app_distribution_subdomain, var.app_domain)
        ingressClassName = "nginx"
        annotations = {
          "nginx.ingress.kubernetes.io/proxy-body-size" = "0"
        }
      }
    })
  ]

  depends_on = [
    kubernetes_namespace_v1.app
  ]
}

resource "helm_release" "app_buildkit" {
  count = var.app_buildkit_enabled ? 1 : 0

  name             = "buildkit"
  repository       = "https://andrcuns.github.io/charts"
  chart            = "buildkit-service"
  version          = "0.10.0"
  namespace        = kubernetes_namespace_v1.app.metadata[0].name
  create_namespace = false

  values = [
    yamlencode({
      fullnameOverride = "buildkit"
      buildkitdToml    = <<-EOT
        debug = true
        [registry."distribution.${var.app_domain}"]
          http = true
          insecure = true
        [worker.oci]
          platforms = [ "linux/amd64" ]
          reservedSpace = "60%"
          maxUsedSpace = "80%"
          max-parallelism = 25
      EOT
      resources = {
        requests = {
          cpu    = "500m"
          memory = "1Gi"
        }
      }
    })
  ]

  depends_on = [
    kubernetes_namespace_v1.app
  ]
}

resource "kubernetes_secret_v1" "app_postgres" {
  count = var.app_postgres_enabled ? 1 : 0

  metadata {
    name      = "app-postgres"
    namespace = var.app_namespace
  }

  data = {
    DATABASE_URL = format("postgresql://%s:%s@postgres.%s.svc.cluster.local:%d/%s",
      var.app_postgres_username,
      one(random_password.app_postgres[*].result),
      var.app_namespace,
      var.app_postgres_port,
      var.app_postgres_database,
    )
  }
}

resource "kubernetes_secret_v1" "app_redis" {
  count = var.app_redis_enabled ? 1 : 0

  metadata {
    name      = "app-redis"
    namespace = var.app_namespace
  }

  data = {
    REDIS_URL = format("redis://:%s@redis-master.%s.svc.cluster.local:%d",
      one(random_password.app_redis[*].result),
      var.app_namespace,
      var.app_redis_port,
    )
  }
}

resource "helm_release" "app_lifecycle_keycloak" {
  count = var.app_lifecycle_keycloak ? 1 : 0

  name             = "lifecycle-keycloak"
  repository       = "oci://ghcr.io/goodrxoss/helm-charts"
  chart            = "lifecycle-keycloak"
  version          = "0.1.1"
  namespace        = kubernetes_namespace_v1.app.metadata[0].name
  create_namespace = false

  values = [
    yamlencode({
      hostname = format("https://keycloak.%s", var.app_domain)

      clients = {
        lifecycleUi = {
          url = format("https://ui.%s", var.app_domain)
        }
      }

      githubIdp = {
        clientId = {
          secretKeyRef = {
            name = "lifecycle-bootstrap"
            key  = "GITHUB_CLIENT_ID"
          }
        }
        clientSecret = {
          secretKeyRef = {
            name = "lifecycle-bootstrap"
            key  = "GITHUB_CLIENT_SECRET"
          }
        }
      }
    })
  ]

  depends_on = [
    kubernetes_namespace_v1.app,
    helm_release.app_lifecycle,
  ]
}

resource "helm_release" "lifecycle_ui" {
  name             = "lifecycle-ui"
  repository       = "oci://ghcr.io/goodrxoss/helm-charts"
  chart            = "lifecycle-ui"
  version          = "0.1.1"
  namespace        = kubernetes_namespace_v1.app.metadata[0].name
  create_namespace = false

  dynamic "set" {
    for_each = kubernetes_secret.image_pull_secret
    content {
      name  = "imagePullSecrets[0].name"
      value = set.value.metadata[0].name
    }
  }

  values = [
    yamlencode({
      image = {
        tag = "0.1.1-alpha.4"
      }
      global = {
        domain      = var.app_domain
        uiSubDomain = "ui"
      }

      config = {
        nextPublicApiUrl          = format("https://app.%s", var.app_domain)
        apiUrl                    = format("https://app.%s", var.app_domain)
        nextPublicKeycloakBaseUrl = format("https://keycloak.%s", var.app_domain)
        keycloakBaseUrl           = format("https://keycloak.%s", var.app_domain)
        nextPublicKeycloakRealm   = "lifecycle"
        keycloakRealm             = "lifecycle"
        keycloakClientId          = "lifecycle-ui"
        keycloakServiceClientId   = "lifecycle-ui-backend"

      }

      secrets = {
        keycloakClientSecret        = "lifecycle-ui-secret"
        keycloakServiceClientSecret = "lifecycle-ui-backend-secret"
      }
    })
  ]

  depends_on = [
    kubernetes_namespace_v1.app,
    helm_release.app_lifecycle_keycloak,
  ]
}

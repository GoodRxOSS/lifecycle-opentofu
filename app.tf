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
  version          = "0.7.0"
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
    yamlencode(merge({
      global = {
        domain = var.app_domain
        image = {
          tag = "0.1.11"
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
                  name  = "ENABLE_AUTH"
                  value = "true"
                },
                {
                  name  = "GITHUB_APP_AUTH_CALLBACK"
                  value = format("https://auth.%s/realms/lifecycle/broker/github/endpoint", var.app_domain)
                },
                {
                  name  = "KEYCLOAK_ISSUER"
                  value = format("https://auth.%s/realms/lifecycle", var.app_domain)
                },
                {
                  name  = "KEYCLOAK_CLIENT_ID"
                  value = "lifecycle-core"
                },
                {
                  name = "KEYCLOAK_JWKS_URL"
                  value = format("https://auth.%s/realms/lifecycle/protocol/openid-connect/certs",
                    var.app_domain,
                  )
                }
              ] : [],
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

      ui = {
        config = {
          apiUrl      = format("https://app.%s", var.app_domain)
          authBaseUrl = format("https://auth.%s", var.app_domain)
        }
      }

      keycloak = merge(
        {
          hostname = format("https://auth.%s", var.app_domain)
          clients = {
            lifecycleUi = {
              url = format("https://ui.%s", var.app_domain)
            }
          }
        },
        var.external_database_enabled ? [{
          keycloakPostgres = {
            enabled = false
          }
          secrets = {
            postgres = {
              enabled = false
            }
          }
          externalDatabase = {
            enabled  = true
            host     = "postgres-keycloak.lifecycle-app.svc.cluster.local"
            port     = var.postgres_keycloak_port
            database = var.postgres_keycloak_database
            username = var.postgres_keycloak_username
            password = {
              secretKeyRef = {
                name = "postgres-keycloak"
                key  = "password"
              }
            }
          }
        }] : []...
      )

      },
      concat(
        var.external_database_enabled ? [{
          postgres = {
            enabled = false
          }

          externalDatabase = {
            enabled  = true
            host     = "postgres-lifecycle.lifecycle-app.svc.cluster.local"
            port     = var.postgres_lifecycle_port
            database = var.postgres_lifecycle_database
            username = var.postgres_lifecycle_username
            password = {
              secretKeyRef = {
                name = "postgres-lifecycle"
                key  = "password"
              }
            }
          }
        }] : [],
        var.app_lifecycle_secrets != {} ? [var.app_lifecycle_secrets] : [],
      )...
    ))
  ]

  depends_on = [
    kubernetes_namespace_v1.app,
    time_sleep.ingress_nginx_controller,
    helm_release.postgres_lifecycle,
    helm_release.postgres_keycloak,
  ]
}

resource "helm_release" "postgres_lifecycle" {
  count = var.postgres_lifecycle_enabled || var.external_database_enabled ? 1 : 0

  name             = "postgres-lifecycle"
  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "postgresql"
  version          = "15.5.19"
  namespace        = kubernetes_namespace_v1.app.metadata[0].name
  create_namespace = false

  values = [
    yamlencode({
      image = {
        repository = "bitnamilegacy/postgresql"
      }
      fullnameOverride = "postgres-lifecycle"
      auth = {
        enabled  = true
        database = var.postgres_lifecycle_database
        username = var.postgres_lifecycle_username
      }
      primary = {
        persistence = {
          enabled = true
          size    = "11Gi"
        }
        # initdb = {
        #   scripts = {
        #     "create_extra_db.sql" = <<-EOT
        #       CREATE DATABASE keycloak;
        #       GRANT ALL PRIVILEGES ON DATABASE keycloak TO lifecycle;
        #       GRANT ALL ON SCHEMA public TO lifecycle;
        #       GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO lifecycle;
        #       GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO lifecycle;
        #     EOT
        #   }
        # }
      }
    })
  ]

  depends_on = [
    kubernetes_namespace_v1.app
  ]
}

resource "helm_release" "postgres_keycloak" {
  count = var.postgres_keycloak_enabled || var.external_database_enabled ? 1 : 0

  name             = "postgres-keycloak"
  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "postgresql"
  version          = "15.5.19"
  namespace        = kubernetes_namespace_v1.app.metadata[0].name
  create_namespace = false

  values = [
    yamlencode({
      image = {
        repository = "bitnamilegacy/postgresql"
      }
      fullnameOverride = "postgres-keycloak"
      auth = {
        enabled  = true
        database = var.postgres_keycloak_database
        username = var.postgres_keycloak_username
      }
      primary = {
        persistence = {
          enabled = true
          size    = "1Gi"
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
      image = {
        repository = "bitnamilegacy/redis"
      }
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
  version          = "0.7.0"
  namespace        = kubernetes_namespace_v1.app.metadata[0].name
  create_namespace = false

  values = [
    yamlencode({
      hostname = format("https://auth.%s", var.app_domain)

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
  count = var.app_lifecycle_ui ? 1 : 0

  name             = "lifecycle-ui"
  repository       = "oci://ghcr.io/goodrxoss/helm-charts"
  chart            = "lifecycle-ui"
  version          = "0.3.0"
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
        tag = "0.1.2"
      }
      global = {
        domain = var.app_domain
      }

      config = {
        apiUrl      = format("https://app.%s", var.app_domain)
        authBaseUrl = format("https://auth.%s", var.app_domain)
        authClientSecret = {
          secretKeyRef = {
            name = "lifecycle-keycloak-lifecycle-ui"
            key  = "clientSecret"
          }
        }
      }
    })
  ]

  depends_on = [
    kubernetes_namespace_v1.app,
    helm_release.app_lifecycle_keycloak,
  ]
}

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

# Debugging tools, useful for cluster testing etc.

locals {
  tools = {
    default = {
      disabled         = true                                         # if you need to temporarity deisable a service but keep the configuration
      namespace        = kubernetes_namespace_v1.app.metadata[0].name # kubernetes namespace to deploy to 
      name             = "default"                                    # alt name, if ommited, key of map will be used
      image            = "gcr.io/kuar-demo/kuard-amd64:1"             # Docker image URL
      port             = "8080"                                       # common port for the service and container
      host             = format("%s.%s", "%s", var.app_domain)        # if no <app>.<host> specified, this hemplate will be used
      args             = []                                           # custom arguments for conteiner command
      backend_protocol = "HTTP"                                       # value for ingress."nginx.ingress.kubernetes.io/backend-protocol"
      service          = true                                         # flag to disable kubernetes serive resource
      ingress          = true                                         # flag to disable kubernetes ingress resource
      tls              = true
    }
    kuard = {
      image = "gcr.io/kuar-demo/kuard-amd64:1"
      port  = 8080
    }
    kuard-wildcard = {
      image          = "gcr.io/kuar-demo/kuard-amd64:1"
      port           = 8080
      host           = format("*.%s", var.app_domain)
      tls            = false
      cluster_issuer = "letsencrypt-dns"
    }
    grpcbin = {
      disabled         = true
      image            = "moul/grpcbin"
      port             = 9000
      backend_protocol = "GRPC"
    }
    grpcui = {
      disabled = true
      image    = "fullstorydev/grpcui:v1.4.3"
      port     = 8080
      args = [
        format("grpcbin.%s:443", var.app_domain),
      ]
    }
    alpine = {
      disabled = true
      image    = "alpine:3.21.3"
      port     = 6379
      args = [
        "tail",
        "-f",
        "/dev/null",
      ]
      service = false
      ingress = false
    }
    alpine-env = {
      disabled = true
      name     = "alpine"
      image    = "alpine:3.21.3"
      args = [
        "tail",
        "-f",
        "/dev/null",
      ]
      service   = false
      ingress   = false
      namespace = "env-shy-dust-159868"
    }
    varkey-socat = {
      disabled = true
      image    = "alpine/socat"
      args = [
        "tcp-listen:6379,fork,reuseaddr",
        format(
          "tcp-connect:redis-master.%s.svc.cluster.local:6379",
          kubernetes_namespace_v1.app.metadata[0].name
        ),
      ]
      service = false
      ingress = false
    }
    postgres-socat = {
      disabled = true
      image    = "alpine/socat"
      port     = 5432
      args = [
        "tcp-listen:5432,fork,reuseaddr",
        format(
          "tcp-connect:postgres-postgresql.%s.svc.cluster.local:5432",
          kubernetes_namespace_v1.app.metadata[0].name
        ),
      ]
      service = false
      ingress = false
    }
  }
  tools0 = {
    for k, v in local.tools : k => v
    if k != "default" && try(v.disabled, false) == false
  }
}

resource "kubernetes_deployment" "this" {
  for_each = local.tools0

  metadata {
    name      = try(each.value.name, each.key)
    namespace = try(each.value.namespace, local.tools.default.namespace)
    labels = {
      app = try(each.value.name, each.key)
    }
  }

  spec {
    replicas = try(each.value.replicas, 1)

    selector {
      match_labels = {
        app = try(each.value.name, each.key)
      }
    }

    template {
      metadata {
        labels = {
          app = try(each.value.name, each.key)
        }
      }

      spec {
        container {
          name              = try(each.value.name, each.key)
          image             = each.value.image
          image_pull_policy = "Always"

          port {
            container_port = try(each.value.port, local.tools.default.port)
          }

          args = try(each.value.args, local.tools.default.args)
        }
      }
    }
  }

  depends_on = [
    kubernetes_namespace_v1.app
  ]
}

resource "kubernetes_service" "this" {
  for_each = {
    for k, v in local.tools0 : k => v if try(v.service, local.tools.default.service)
  }

  metadata {
    name      = try(each.value.name, each.key)
    namespace = try(each.value.namespace, local.tools.default.namespace)
  }

  spec {
    selector = {
      app = kubernetes_deployment.this[each.key].metadata[0].labels["app"]
    }

    port {
      port        = try(each.value.port, local.tools.default.port)
      target_port = try(each.value.port, local.tools.default.port)
      protocol    = "TCP"
    }
  }

  depends_on = [
    kubernetes_namespace_v1.app
  ]
}

resource "kubernetes_ingress_v1" "this" {
  for_each = {
    for k, v in local.tools0 : k => v if try(v.ingress, local.tools.default.ingress)
  }

  metadata {
    name      = try(each.value.name, each.key)
    namespace = try(each.value.namespace, local.tools.default.namespace)
    annotations = {
      "kubernetes.io/ingress.class"                  = try(each.value.ingress_class, "nginx")
      "cert-manager.io/cluster-issuer"               = try(each.value.cluster_issuer, "letsencrypt")
      "nginx.ingress.kubernetes.io/backend-protocol" = try(each.value.backend_protocol, local.tools.default.backend_protocol)
    }
  }

  spec {
    ingress_class_name = "nginx"

    dynamic "tls" {
      for_each = try(each.value.tls, local.tools.default.tls) ? [1] : []

      content {
        hosts = [
          try(each.value.host,
            format(
              local.tools.default.host,
              try(each.value.name, each.key)
            )
          )
        ]
        secret_name = try(each.value.host,
          format(
            local.tools.default.host,
            try(each.value.name, each.key)
          )
        )
      }
    }

    rule {
      host = try(each.value.host,
        format(local.tools.default.host,
          try(each.value.name, each.key)
        )
      )
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.this[each.key].metadata[0].name
              port {
                number = each.value.port
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_namespace_v1.app
  ]
}

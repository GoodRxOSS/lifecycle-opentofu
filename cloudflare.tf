locals {
  cloudflare_tunnel_domain = (var.cloudflare_tunnel_domain != null
    ? var.cloudflare_tunnel_domain
    : var.app_domain
  )

  ingress_nginx_controller_svc = format("http://%s.%s.svc.cluster.local:%d",
    data.kubernetes_service.ingress_nginx_controller.metadata[0].name,
    data.kubernetes_service.ingress_nginx_controller.metadata[0].namespace,
    data.kubernetes_service.ingress_nginx_controller.spec[0].port[0].port,
  )
}

resource "random_password" "cloudflare_tunnel" {
  count = var.cloudflare_tunnel_enabled ? 1 : 0

  length  = 64
  special = false
}

data "cloudflare_zone" "this" {
  count = var.cloudflare_tunnel_enabled ? 1 : 0

  filter = {
    name = join(".",
      slice(split(".", local.cloudflare_tunnel_domain),
        length(split(".", local.cloudflare_tunnel_domain)) - 2,
        length(split(".", local.cloudflare_tunnel_domain)),
      )
    )
  }
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "this" {
  count = var.cloudflare_tunnel_enabled ? 1 : 0

  account_id = one(data.cloudflare_zone.this[*].account.id)
  name       = var.cloudflare_tunnel_name
  config_src = "local"
  tunnel_secret = base64encode(
    one(random_password.cloudflare_tunnel[*].result)
  )
}

module "cloudflare_tunnel" {
  count = var.cloudflare_tunnel_enabled ? 1 : 0

  source = "./modules/cloudflare-dns"

  dns_domain      = local.cloudflare_tunnel_domain
  dns_record_type = "CNAME"
  dns_ttl         = 1
  dns_proxied     = true
  dns_record_value = format("%s.cfargotunnel.com",
    one(cloudflare_zero_trust_tunnel_cloudflared.this[*].id),
  )
}

resource "helm_release" "cloudflare_tunnel" {
  count = var.cloudflare_tunnel_enabled ? 1 : 0

  name             = "cloudflare-tunnel"
  repository       = "https://cloudflare.github.io/helm-charts"
  chart            = "cloudflare-tunnel"
  namespace        = "cloudflare"
  version          = "0.3.2"
  create_namespace = true

  values = [
    yamlencode({
      image = {
        tag = "2026.1.2"
      }
      cloudflare = {
        account    = one(data.cloudflare_zone.this[*].account.id)
        tunnelName = one(cloudflare_zero_trust_tunnel_cloudflared.this[*].name)
        tunnelId   = one(cloudflare_zero_trust_tunnel_cloudflared.this[*].id)
        secret = base64encode(
          one(random_password.cloudflare_tunnel[*].result)
        )
        ingress = [
          {
            hostname = local.cloudflare_tunnel_domain
            service  = local.ingress_nginx_controller_svc
            path     = "/*/"
            originRequest = {
              httpHostHeader   = format("cloudflare.%s", local.cloudflare_tunnel_domain)
              originServerName = format("cloudflare.%s", local.cloudflare_tunnel_domain)
              connectTimeout   = "30s"
              noTLSVerify      = false
            }
          },
        ]
      }
    })
  ]
}

resource "kubernetes_ingress_v1" "cloudflare_tunnel" {
  count = var.cloudflare_tunnel_enabled ? 1 : 0

  metadata {
    name      = "cloudflare"
    namespace = one(helm_release.cloudflare_tunnel[*].metadata[0].namespace)
    annotations = {
      "nginx.ingress.kubernetes.io/server-snippet" = <<-EOT
        location ~ ^/([a-zA-Z0-9_-]+)(.*) {
            set $subdomain $1;
            set $rest $2;
            rewrite ^.*$ $rest break;
            add_header X-Debug-Subdomain $subdomain;
            add_header X-Debug-Rest $rest;
            proxy_set_header Host "$subdomain.${local.cloudflare_tunnel_domain}";
            proxy_pass ${local.ingress_nginx_controller_svc};
        }
      EOT
    }
  }

  spec {
    ingress_class_name = "nginx"
    rule {
      host = format("cloudflare.%s", local.cloudflare_tunnel_domain)
    }
  }

  depends_on = [
    helm_release.cloudflare_tunnel,
  ]
}

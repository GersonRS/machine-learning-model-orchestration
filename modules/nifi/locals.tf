locals {
  domain      = format("nifi.%s", trimprefix("${var.subdomain}.${var.base_domain}", "."))
  domain_full = format("nifi.%s.%s", trimprefix("${var.subdomain}.${var.cluster_name}", "."), var.base_domain)

  helm_values_nifikop = [{
    nifikop = {
      image = {
        tag = "v1.7.0-release"
      }
      resources = {
        requests = {
          memory = "256Mi"
          cpu    = "250m"
        }
        limits = {
          memory = "256Mi"
          cpu    = "550m"
        }
      }
      namespaces = [var.namespace]
    }
  }]
  helm_values_nifi = [{
    nifi = {
      prometheus = {
        servicemonitor = {
          enabled = var.enable_service_monitor
        }
      }
      oidc = {
        enabled       = true
        url           = "${var.oidc.issuer_url}/.well-known/openid-configuration"
        client_id     = "${var.oidc.client_id}"
        client_secret = "${var.oidc.client_secret}"
      }
      ingress = {
        enabled = true
        annotations = {
          "cert-manager.io/cluster-issuer"                   = "${var.cluster_issuer}"
          "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure"
          "traefik.ingress.kubernetes.io/router.tls"         = "true"
        }
        hosts = [
          {
            host = local.domain
            path = "/nifi"
          },
          {
            host = local.domain_full
            path = "/nifi"
          },
        ]
        tls = [{
          secretName = "nifi-tls"
          hosts = [
            local.domain,
            local.domain_full,
          ]
        }]
      }
    }
  }]
}

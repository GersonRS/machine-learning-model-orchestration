locals {
  domain      = format("vault.%s", trimprefix("${var.subdomain}.${var.base_domain}", "."))
  domain_full = format("vault.%s.%s", trimprefix("${var.subdomain}.${var.cluster_name}", "."), var.base_domain)

  helm_values = [{
    vault = {
      # ui = {
      #   enabled     = true
      #   serviceType = "LoadBalancer"
      # }
      server = {
        ingress = {
          enabled = true
          annotations = {
            "cert-manager.io/cluster-issuer"                   = "${var.cluster_issuer}"
            "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure"
            "traefik.ingress.kubernetes.io/router.tls"         = "true"
          }
          ingressClassName = "traefik"
          hosts = [
            {
              host = local.domain
            },
            {
              host = local.domain_full
            }
          ]
          tls = [{
            secretName = "vault-ingres-tls"
            hosts = [
              local.domain,
              local.domain_full,
            ]
          }]
        }
      }
    }
  }]
}

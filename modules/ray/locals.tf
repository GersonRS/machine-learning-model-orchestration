locals {
  domain      = format("ray.%s", trimprefix("${var.subdomain}.${var.base_domain}", "."))
  domain_full = format("ray.%s.%s", trimprefix("${var.subdomain}.${var.cluster_name}", "."), var.base_domain)

  helm_values = [{
    ray-cluster = {
      image = {
        repository = "gersonrs/ray"
        tag        = "v1.0.3"
      }

      head = {
        # containerEnv = []
        # - name: EXAMPLE_ENV
        #   value: "1"
        # envFrom = []
        # - secretRef:
        #     name: my-env-secret
        resources = {
          limits = {
            cpu    = 2
            memory = "4G"
          }
          requests = {
            cpu    = 1
            memory = "2G"
          }
        }
      }
      worker = {
        replicas = 2
        resources = {
          limits = {
            cpu    = 2
            memory = "4G"
          }
          requests = {
            cpu    = 1
            memory = "2G"
          }
        }
      }
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
          path = "/"
        },
        {
          host = local.domain_full
          path = "/"
        },
      ]
      tls = [{
        secretName = "ray-ingres-tls"
        hosts = [
          local.domain,
          local.domain_full
        ]
      }]
    }

  }]
}

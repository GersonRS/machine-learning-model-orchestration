locals {
  domain      = format("kafka-ui.%s", trimprefix("${var.subdomain}.${var.base_domain}", "."))
  domain_full = format("kafka-ui.%s.%s", trimprefix("${var.subdomain}.${var.cluster_name}", "."), var.base_domain)

  helm_values = [{
    kafka-ui = {
      yamlApplicationConfig = {
        kafka = {
          clusters = [{
            name             = "local"
            bootstrapServers = "${var.kafka_broker_name}-kafka-bootstrap.ingestion.svc.cluster.local:9092"
            schemaRegistry   = "http://schema-registry-cp-schema-registry.ingestion.svc.cluster.local:8081"
            # schemaRegistryAuth = {
            #   username = "username"
            #   password = "password"
            # }
            # metrics = {
            #   port = "9997"
            #   type = "JMX"
            # }
            #     schemaNameTemplate: "%s-value"
          }]
        }
        # spring = {
        #   security = {
        #     oauth2 = false
        #   }
        # }
        auth = {
          type = "disabled"
        }
        management = {
          health = {
            ldap = {
              enabled = false
            }
          }
        }
      }

      ingress = {
        # -- Specifies if you want to create an ingress access
        enabled : true
        # -- New style ingress class name. Only possible if you use K8s 1.18.0 or later version
        ingressClassName : "traefik"
        # -- Additional ingress annotations
        annotations = {
          "cert-manager.io/cluster-issuer"                   = "${var.cluster_issuer}"
          "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure"
          "traefik.ingress.kubernetes.io/router.tls"         = "true"
        }
        host = local.domain_full
        # -- Ingress tls configuration for https access
        tls = {
          enabled    = true
          secretName = "kafka-ui-ingres-tls"
        }
      }
    }
  }]
}

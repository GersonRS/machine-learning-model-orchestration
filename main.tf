module "kind" {
  source             = "./modules/kind"
  cluster_name       = local.cluster_name
  kubernetes_version = local.kubernetes_version
}

module "metallb" {
  source = "./modules/metallb"
  subnet = module.kind.kind_subnet
}

module "argocd_bootstrap" {
  source = "./modules/argocd_bootstrap"
  argocd_projects = {
    "${local.cluster_name}" = {
      destination_cluster = "in-cluster"
    }
  }
  depends_on = [module.kind]
}

# module "metrics-server" {
#   source               = "./modules/metrics-server"
#   argocd_project       = local.cluster_name
#   kubelet_insecure_tls = true
#   target_revision      = local.target_revision
#   project_source_repo  = local.project_source_repo
#   dependency_ids = {
#     argocd = module.argocd_bootstrap.id
#   }
# }

module "traefik" {
  source                 = "./modules/traefik/kind"
  argocd_project         = local.cluster_name
  enable_service_monitor = local.enable_service_monitor
  target_revision        = local.target_revision
  project_source_repo    = local.project_source_repo
  dependency_ids = {
    argocd = module.argocd_bootstrap.id
  }
}

module "cert-manager" {
  source                 = "./modules/cert-manager/self-signed"
  argocd_project         = local.cluster_name
  enable_service_monitor = local.enable_service_monitor
  target_revision        = local.target_revision
  project_source_repo    = local.project_source_repo
  dependency_ids = {
    argocd = module.argocd_bootstrap.id
  }
}


# module "istio" {
#   source                 = "./modules/istio"
#   argocd_project         = local.cluster_name
#   enable_service_monitor = local.enable_service_monitor
#   target_revision        = local.target_revision
#   project_source_repo    = local.project_source_repo
#   dependency_ids = {
#     argocd = module.argocd_bootstrap.id
#   }
# }


# module "knative" {
#   source                 = "./modules/knative"
#   argocd_project         = local.cluster_name
#   base_domain            = local.gateway_base_domain
#   enable_service_monitor = local.enable_service_monitor
#   target_revision        = local.target_revision
#   project_source_repo    = local.project_source_repo
#   dependency_ids = {
#     istio        = module.istio.id
#     cert-manager = module.cert-manager.id
#   }
# }

# module "kserve" {
#   source                 = "./modules/kserve"
#   argocd_project         = local.cluster_name
#   enable_service_monitor = local.enable_service_monitor
#   target_revision        = local.target_revision
#   project_source_repo    = local.project_source_repo
#   dependency_ids = {
#     knative = module.knative.id
#   }
# }

# module "reflector" {
#   source                 = "./modules/reflector"
#   argocd_project         = local.cluster_name
#   enable_service_monitor = local.enable_service_monitor
#   target_revision        = local.target_revision
#   project_source_repo    = local.project_source_repo
#   dependency_ids = {
#     argocd = module.argocd_bootstrap.id
#   }
# }

# module "postgresql" {
#   source                 = "./modules/postgresql"
#   cluster_name           = local.cluster_name
#   base_domain            = local.base_domain
#   cluster_issuer         = local.cluster_issuer
#   argocd_project         = local.cluster_name
#   enable_service_monitor = local.enable_service_monitor
#   target_revision        = local.target_revision
#   project_source_repo    = local.project_source_repo
#   dependency_ids = {
#     argocd = module.argocd_bootstrap.id
#   }
# }

module "keycloak" {
  source              = "./modules/keycloak"
  cluster_name        = local.cluster_name
  base_domain         = local.base_domain
  subdomain           = local.subdomain
  cluster_issuer      = local.cluster_issuer
  argocd_project      = local.cluster_name
  target_revision     = local.target_revision
  project_source_repo = local.project_source_repo
  dependency_ids = {
    traefik      = module.traefik.id
    cert-manager = module.cert-manager.id
  }
}

module "oidc" {
  source         = "./modules/oidc"
  cluster_name   = local.cluster_name
  base_domain    = local.base_domain
  subdomain      = local.subdomain
  cluster_issuer = local.cluster_issuer
  dependency_ids = {
    keycloak = module.keycloak.id
  }
}


# module "zookeeper" {
#   source                 = "./modules/zookeeper"
#   argocd_project         = local.cluster_name
#   enable_service_monitor = local.enable_service_monitor
#   target_revision        = local.target_revision
#   project_source_repo    = local.project_source_repo
#   dependency_ids = {
#     argocd = module.argocd_bootstrap.id
#   }
# }

# module "nifi" {
#   source                 = "./modules/nifi"
#   cluster_name           = local.cluster_name
#   base_domain            = local.base_domain
#   subdomain              = local.subdomain
#   cluster_issuer         = local.cluster_issuer
#   argocd_project         = local.cluster_name
#   enable_service_monitor = local.enable_service_monitor
#   oidc                   = module.oidc.oidc
#   target_revision        = local.target_revision
#   project_source_repo    = local.project_source_repo
#   dependency_ids = {
#     oidc      = module.oidc.id
#     zookeeper = module.zookeeper.id
#   }
# }

module "minio" {
  source                 = "./modules/minio"
  cluster_name           = local.cluster_name
  base_domain            = local.base_domain
  subdomain              = local.subdomain
  cluster_issuer         = local.cluster_issuer
  argocd_project         = local.cluster_name
  enable_service_monitor = local.enable_service_monitor
  config_minio           = local.minio_config
  oidc                   = module.oidc.oidc
  target_revision        = local.target_revision
  project_source_repo    = local.project_source_repo
  dependency_ids = {
    traefik      = module.traefik.id
    cert-manager = module.cert-manager.id
    oidc         = module.oidc.id
  }
}

# module "loki-stack" {
#   source              = "./modules/loki-stack/kind"
#   argocd_project      = local.cluster_name
#   target_revision     = local.target_revision
#   project_source_repo = local.project_source_repo
#   logs_storage = {
#     bucket_name = local.minio_config.buckets.0.name
#     endpoint    = module.minio.endpoint
#     access_key  = local.minio_config.users.0.accessKey
#     secret_key  = local.minio_config.users.0.secretKey
#   }
#   dependency_ids = {
#     minio = module.minio.id
#   }
# }

# module "thanos" {
#   source                 = "./modules/thanos/kind"
#   cluster_name           = local.cluster_name
#   base_domain            = local.base_domain
#   subdomain              = local.subdomain
#   cluster_issuer         = local.cluster_issuer
#   argocd_project         = local.cluster_name
#   enable_service_monitor = local.enable_service_monitor
#   target_revision        = local.target_revision
#   project_source_repo    = local.project_source_repo
#   metrics_storage = {
#     bucket_name = local.minio_config.buckets.1.name
#     endpoint    = module.minio.endpoint
#     access_key  = local.minio_config.users.1.accessKey
#     secret_key  = local.minio_config.users.1.secretKey
#   }
#   thanos = {
#     oidc = module.oidc.oidc
#   }
#   dependency_ids = {
#     argocd       = module.argocd_bootstrap.id
#     traefik      = module.traefik.id
#     cert-manager = module.cert-manager.id
#     minio        = module.minio.id
#     keycloak     = module.keycloak.id
#     oidc         = module.oidc.id
#   }
# }

# module "kube-prometheus-stack" {
#   source              = "./modules/kube-prometheus-stack/kind"
#   cluster_name        = local.cluster_name
#   base_domain         = local.base_domain
#   subdomain           = local.subdomain
#   cluster_issuer      = local.cluster_issuer
#   argocd_project      = local.cluster_name
#   target_revision     = local.target_revision
#   project_source_repo = local.project_source_repo
#   metrics_storage_main = {
#     bucket_name = local.minio_config.buckets.1.name
#     endpoint    = module.minio.endpoint
#     access_key  = local.minio_config.users.1.accessKey
#     secret_key  = local.minio_config.users.1.secretKey
#   }
#   prometheus = {
#     oidc = module.oidc.oidc
#   }
#   alertmanager = {
#     oidc = module.oidc.oidc
#   }
#   grafana = {
#     oidc = module.oidc.oidc
#   }
#   dependency_ids = {
#     traefik      = module.traefik.id
#     cert-manager = module.cert-manager.id
#     minio        = module.minio.id
#     oidc         = module.oidc.id
#   }
# }

# module "spark" {
#   source                 = "./modules/spark"
#   argocd_project         = local.cluster_name
#   enable_service_monitor = local.enable_service_monitor
#   target_revision        = local.target_revision
#   project_source_repo    = local.project_source_repo
#   dependency_ids = {
#     argocd = module.argocd_bootstrap.id
#   }
# }

# module "strimzi" {
#   source                 = "./modules/strimzi"
#   argocd_project         = local.cluster_name
#   enable_service_monitor = local.enable_service_monitor
#   target_revision        = local.target_revision
#   project_source_repo    = local.project_source_repo
#   dependency_ids = {
#     argocd = module.argocd_bootstrap.id
#   }
# }

# module "kafka" {
#   source                 = "./modules/kafka"
#   argocd_project         = local.cluster_name
#   enable_service_monitor = local.enable_service_monitor
#   target_revision        = local.target_revision
#   project_source_repo    = local.project_source_repo
#   dependency_ids = {
#     argocd  = module.argocd_bootstrap.id
#     traefik = module.traefik.id
#     strimzi = module.strimzi.id
#   }
# }

# module "cp-schema-registry" {
#   source                 = "./modules/cp-schema-registry"
#   argocd_project         = local.cluster_name
#   enable_service_monitor = local.enable_service_monitor
#   target_revision        = local.target_revision
#   project_source_repo    = local.project_source_repo
#   kafka_broker_name      = module.kafka.broker_name
#   dependency_ids = {
#     argocd = module.argocd_bootstrap.id
#     kafka  = module.kafka.id
#   }
# }

# module "kafka-ui" {
#   source                 = "./modules/kafka-ui"
#   cluster_name           = local.cluster_name
#   base_domain            = local.base_domain
#   subdomain              = local.subdomain
#   cluster_issuer         = local.cluster_issuer
#   argocd_project         = local.cluster_name
#   enable_service_monitor = local.enable_service_monitor
#   target_revision        = local.target_revision
#   project_source_repo    = local.project_source_repo
#   kafka_broker_name      = module.kafka.broker_name
#   dependency_ids = {
#     argocd             = module.argocd_bootstrap.id
#     kafka              = module.kafka.id
#     cp-schema-registry = module.cp-schema-registry.id
#   }
# }

# module "mysql" {
#   source                 = "./modules/mysql"
#   argocd_project         = local.cluster_name
#   enable_service_monitor = local.enable_service_monitor
#   target_revision        = local.target_revision
#   project_source_repo    = local.project_source_repo
#   dependency_ids = {
#     argocd  = module.argocd_bootstrap.id
#     traefik = module.traefik.id
#   }
# }

# # module "vault" {
# #   source                 = "./modules/vault"
# #   cluster_name           = local.cluster_name
# #   base_domain            = local.base_domain
# #   subdomain              = local.subdomain
# #   cluster_issuer         = local.cluster_issuer
# #   argocd_project         = local.cluster_name
# #   enable_service_monitor = local.enable_service_monitor
# #   target_revision        = local.target_revision
# #   project_source_repo    = local.project_source_repo
# #   dependency_ids = {
# #     argocd  = module.argocd_bootstrap.id
# #     traefik = module.traefik.id
# #   }
# # }

# module "pinot" {
#   source                 = "./modules/pinot"
#   cluster_name           = local.cluster_name
#   base_domain            = local.base_domain
#   subdomain              = local.subdomain
#   cluster_issuer         = local.cluster_issuer
#   argocd_project         = local.cluster_name
#   enable_service_monitor = local.enable_service_monitor
#   target_revision        = local.target_revision
#   project_source_repo    = local.project_source_repo
#   storage = {
#     bucket_name       = "pinot"
#     endpoint          = module.minio.endpoint
#     access_key        = module.minio.minio_root_user_credentials.username
#     secret_access_key = module.minio.minio_root_user_credentials.password
#   }
#   dependency_ids = {
#     argocd  = module.argocd_bootstrap.id
#     traefik = module.traefik.id
#     oidc    = module.oidc.id
#     minio   = module.minio.id
#   }
# }

# module "trino" {
#   source                 = "./modules/trino"
#   cluster_name           = local.cluster_name
#   base_domain            = local.base_domain
#   subdomain              = local.subdomain
#   cluster_issuer         = local.cluster_issuer
#   argocd_project         = local.cluster_name
#   enable_service_monitor = local.enable_service_monitor
#   target_revision        = local.target_revision
#   project_source_repo    = local.project_source_repo
#   pinot_dns              = module.pinot.cluster_dns
#   storage = {
#     bucket_name       = "trino"
#     endpoint          = module.minio.endpoint
#     access_key        = module.minio.minio_root_user_credentials.username
#     secret_access_key = module.minio.minio_root_user_credentials.password
#   }
#   database = {
#     user     = module.postgresql.credentials.user
#     password = module.postgresql.credentials.password
#     database = "curated"
#     service  = module.postgresql.cluster_ip
#   }
#   dependency_ids = {
#     argocd     = module.argocd_bootstrap.id
#     traefik    = module.traefik.id
#     oidc       = module.oidc.id
#     minio      = module.minio.id
#     postgresql = module.postgresql.id
#     pinot      = module.pinot.id
#   }
# }

# module "mlflow" {
#   source                 = "./modules/mlflow"
#   cluster_name           = local.cluster_name
#   base_domain            = local.base_domain
#   subdomain              = local.subdomain
#   cluster_issuer         = local.cluster_issuer
#   argocd_project         = local.cluster_name
#   enable_service_monitor = local.enable_service_monitor
#   target_revision        = local.target_revision
#   project_source_repo    = local.project_source_repo
#   storage = {
#     bucket_name       = "mlflow"
#     endpoint          = module.minio.endpoint
#     access_key        = module.minio.minio_root_user_credentials.username
#     secret_access_key = module.minio.minio_root_user_credentials.password
#   }
#   database = {
#     user     = module.postgresql.credentials.user
#     password = module.postgresql.credentials.password
#     database = "mlflow"
#     service  = module.postgresql.cluster_dns
#   }
#   dependency_ids = {
#     argocd     = module.argocd_bootstrap.id
#     traefik    = module.traefik.id
#     minio      = module.minio.id
#     postgresql = module.postgresql.id
#   }
# }

module "ray" {
  source                 = "./modules/ray"
  cluster_name           = local.cluster_name
  base_domain            = local.base_domain
  subdomain              = local.subdomain
  cluster_issuer         = local.cluster_issuer
  argocd_project         = local.cluster_name
  enable_service_monitor = local.enable_service_monitor
  target_revision        = local.target_revision
  project_source_repo    = local.project_source_repo
  dependency_ids = {
    argocd  = module.argocd_bootstrap.id
    traefik = module.traefik.id
  }
}

# module "jupyterhub" {
#   source                 = "./modules/jupyterhub"
#   cluster_name           = local.cluster_name
#   base_domain            = local.base_domain
#   subdomain              = local.subdomain
#   cluster_issuer         = local.cluster_issuer
#   argocd_project         = local.cluster_name
#   enable_service_monitor = local.enable_service_monitor
#   target_revision        = local.target_revision
#   project_source_repo    = local.project_source_repo
#   oidc                   = module.oidc.oidc
#   storage = {
#     bucket_name       = "jupyterhub"
#     endpoint          = module.minio.endpoint
#     access_key        = module.minio.minio_root_user_credentials.username
#     secret_access_key = module.minio.minio_root_user_credentials.password
#   }
#   database = {
#     user     = module.postgresql.credentials.user
#     password = module.postgresql.credentials.password
#     database = "jupyterhub"
#     endpoint = module.postgresql.cluster_dns
#   }
#   mlflow = {
#     endpoint = module.mlflow.cluster_dns
#   }
#   # ray = {
#   #   endpoint = module.ray.cluster_dns
#   # }
#   dependency_ids = {
#     argocd     = module.argocd_bootstrap.id
#     traefik    = module.traefik.id
#     oidc       = module.oidc.id
#     minio      = module.minio.id
#     postgresql = module.postgresql.id
#     mlflow     = module.mlflow.id
#     # ray        = module.ray.id
#   }
# }

# module "airflow" {
#   source                 = "./modules/airflow"
#   cluster_name           = local.cluster_name
#   base_domain            = local.base_domain
#   subdomain              = local.subdomain
#   cluster_issuer         = local.cluster_issuer
#   argocd_project         = local.cluster_name
#   enable_service_monitor = local.enable_service_monitor
#   target_revision        = local.target_revision
#   project_source_repo    = local.project_source_repo
#   oidc                   = module.oidc.oidc
#   fernetKey              = local.airflow_fernetKey
#   storage = {
#     bucket_name       = "airflow"
#     endpoint          = module.minio.endpoint
#     access_key        = module.minio.minio_root_user_credentials.username
#     secret_access_key = module.minio.minio_root_user_credentials.password
#   }
#   database = {
#     user     = module.postgresql.credentials.user
#     password = module.postgresql.credentials.password
#     database = "airflow"
#     endpoint = module.postgresql.cluster_dns
#   }
#   mlflow = {
#     endpoint = module.mlflow.cluster_dns
#   }
#   # ray = {
#   #   endpoint = module.ray.cluster_dns
#   # }
#   dependency_ids = {
#     argocd     = module.argocd_bootstrap.id
#     traefik    = module.traefik.id
#     oidc       = module.oidc.id
#     minio      = module.minio.id
#     postgresql = module.postgresql.id
#     mlflow     = module.mlflow.id
#     # ray        = module.ray.id
#   }
# }

# module "gitlab" {
#   source                 = "./modules/gitlab"
#   cluster_name           = local.cluster_name
#   base_domain            = local.base_domain
#   subdomain              = local.subdomain
#   cluster_issuer         = local.cluster_issuer
#   argocd_project         = local.cluster_name
#   enable_service_monitor = local.enable_service_monitor
#   target_revision        = local.target_revision
#   project_source_repo    = local.project_source_repo
#   oidc                   = module.oidc.oidc
#   metrics_storage = {
#     bucket_name       = "registry"
#     endpoint          = module.minio.endpoint
#     access_key        = module.minio.minio_root_user_credentials.username
#     secret_access_key = module.minio.minio_root_user_credentials.password
#   }
#   dependency_ids = {
#     argocd  = module.argocd_bootstrap.id
#     traefik = module.traefik.id
#     oidc    = module.oidc.id
#     minio   = module.minio.id
#   }
# }

module "argocd" {
  source                   = "./modules/argocd"
  base_domain              = local.base_domain
  cluster_name             = local.cluster_name
  subdomain                = local.subdomain
  cluster_issuer           = local.cluster_issuer
  enable_service_monitor   = local.enable_service_monitor
  server_secretkey         = module.argocd_bootstrap.argocd_server_secretkey
  accounts_pipeline_tokens = module.argocd_bootstrap.argocd_accounts_pipeline_tokens
  argocd_project           = local.cluster_name
  admin_enabled            = false
  exec_enabled             = true
  target_revision          = local.target_revision
  project_source_repo      = local.project_source_repo
  oidc = {
    name         = "OIDC"
    issuer       = module.oidc.oidc.issuer_url
    clientID     = module.oidc.oidc.client_id
    clientSecret = module.oidc.oidc.client_secret
    requestedIDTokenClaims = {
      groups = {
        essential = true
      }
    }
  }
  rbac = {
    policy_csv = <<-EOT
      g, pipeline, role:admin
      g, modern-gitops-stack-admins, role:admin
    EOT
  }
  dependency_ids = {
    traefik      = module.traefik.id
    cert-manager = module.cert-manager.id
    oidc         = module.oidc.id
    # kube-prometheus-stack = module.kube-prometheus-stack.id
  }
}



# kubectl apply -n kserve-test -f - <<EOF
# apiVersion: "serving.kserve.io/v1beta1"
# kind: "InferenceService"
# metadata:
#   name: "sklearn-iris"
# annotations:
#   serving.kserve.io/enable-prometheus-scraping: "true"
# spec:
#   predictor:
#     model:
#       args: ["--enable_docs_url=True"]
#       modelFormat:
#         name: sklearn
#       protocolVersion: v2
#       storageUri: "s3://mlflow/0/094aee50826a45c09a2227ce8589ee3d/artifacts/random-forest-model/model.pkl"
# EOF

# cat <<EOF > "./iris-input.json"
# {
#   "instances": [
#     [6.8,  2.8],
#     [6.0,  3.4]
#   ]
# }
# EOF

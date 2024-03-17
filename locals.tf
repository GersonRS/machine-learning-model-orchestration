locals {
  kubernetes_version     = "v1.27.3"
  cluster_name           = "kind"
  base_domain            = format("%s.nip.io", replace(module.traefik.external_ip, ".", "-"))
  gateway_base_domain    = format("%s.nip.io", replace(module.istio.external_ip, ".", "-"))
  subdomain              = "apps"
  cluster_issuer         = module.cert-manager.cluster_issuers.ca
  enable_service_monitor = false # Can be enabled after the first bootstrap.
  app_autosync           = { allow_empty = false, prune = true, self_heal = true }
  target_revision        = "develop"
  project_source_repo    = "https://github.com/GersonRS/machine-learning-model-orchestration.git"
  airflow_fernetKey      = base64encode(resource.random_password.airflow_fernetKey.result)
}

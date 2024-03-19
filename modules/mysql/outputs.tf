output "id" {
  description = "ID to pass other modules in order to refer to this module as a dependency."
  value       = resource.null_resource.this.id
}

output "credentials" {
  value = local.credentials
}

output "cluster_dns" {
  description = "mysql cluster dns"
  value       = "mysql.${var.namespace}.svc.cluster.local"
}
output "cluster_ip" {
  description = "mysql cluster ip internal"
  value       = data.kubernetes_service.mysql.spec[0].cluster_ip
}

output "external_ip" {
  description = "Mysql External IPs"
  value       = data.kubernetes_service.mysql.status[0].load_balancer[0].ingress[0].ip
}

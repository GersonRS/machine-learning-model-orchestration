locals {
  helm_values = [{
    domain = "${var.base_domain}"
  }]
}

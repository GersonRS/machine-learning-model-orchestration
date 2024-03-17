resource "null_resource" "dependencies" {
  triggers = var.dependency_ids
}

resource "argocd_project" "this" {
  count = var.argocd_project == null ? 1 : 0

  metadata {
    name      = var.destination_cluster != "in-cluster" ? "kserve-${var.destination_cluster}" : "kserve"
    namespace = var.argocd_namespace
    annotations = {
      "modern-gitops-stack.io/argocd_namespace" = var.argocd_namespace
    }
  }

  spec {
    description  = "kserve application project for cluster ${var.destination_cluster}"
    source_repos = [var.project_source_repo]


    destination {
      name      = var.destination_cluster
      namespace = var.namespace
    }
    destination {
      name      = var.destination_cluster
      namespace = "kube-system"
    }

    orphaned_resources {
      warn = true
    }

    cluster_resource_whitelist {
      group = "*"
      kind  = "*"
    }
  }
}

data "utils_deep_merge_yaml" "values" {
  input = [for i in concat(local.helm_values, var.helm_values) : yamlencode(i)]
}

resource "argocd_application" "this" {
  metadata {
    name      = var.destination_cluster != "in-cluster" ? "kserve-${var.destination_cluster}" : "kserve"
    namespace = var.argocd_namespace
    labels = merge({
      "application" = "kserve"
      "cluster"     = var.destination_cluster
    }, var.argocd_labels)
  }

  timeouts {
    create = "15m"
    delete = "15m"
  }

  wait = var.app_autosync == { "allow_empty" = tobool(null), "prune" = tobool(null), "self_heal" = tobool(null) } ? false : true

  spec {
    project = var.argocd_project == null ? argocd_project.this[0].metadata.0.name : var.argocd_project

    source {
      repo_url        = var.project_source_repo
      path            = "charts/kserve/templates"
      target_revision = var.target_revision
      directory {
        recurse = true
      }
    }

    ignore_difference {
      group         = "admissionregistration.k8s.io"
      kind          = "MutatingWebhookConfiguration"
      name          = "inferenceservice.serving.kserve.io"
      json_pointers = ["/webhooks"]
    }

    ignore_difference {
      group         = "admissionregistration.k8s.io"
      kind          = "ValidatingWebhookConfiguration"
      name          = "clusterservingruntime.serving.kserve.io"
      json_pointers = ["/webhooks/0/clientConfig/caBundle"]
    }

    ignore_difference {
      group         = "admissionregistration.k8s.io"
      kind          = "ValidatingWebhookConfiguration"
      name          = "inferencegraph.serving.kserve.io"
      json_pointers = ["/webhooks/0/clientConfig/caBundle"]
    }

    ignore_difference {
      group         = "admissionregistration.k8s.io"
      kind          = "ValidatingWebhookConfiguration"
      name          = "inferenceservice.serving.kserve.io"
      json_pointers = ["/webhooks/0/clientConfig/caBundle"]
    }

    ignore_difference {
      group         = "admissionregistration.k8s.io"
      kind          = "ValidatingWebhookConfiguration"
      name          = "servingruntime.serving.kserve.io"
      json_pointers = ["/webhooks/0/clientConfig/caBundle"]
    }

    ignore_difference {
      group         = "admissionregistration.k8s.io"
      kind          = "ValidatingWebhookConfiguration"
      name          = "trainedmodel.serving.kserve.io"
      json_pointers = ["/webhooks/0/clientConfig/caBundle"]
    }

    destination {
      name      = var.destination_cluster
      namespace = var.namespace
    }

    sync_policy {
      dynamic "automated" {
        for_each = toset(var.app_autosync == { "allow_empty" = tobool(null), "prune" = tobool(null), "self_heal" = tobool(null) } ? [] : [var.app_autosync])
        content {
          prune       = automated.value.prune
          self_heal   = automated.value.self_heal
          allow_empty = true
        }
      }

      retry {
        backoff {
          duration     = "20s"
          max_duration = "2m"
          factor       = "2"
        }
        limit = "5"
      }

      sync_options = [
        "CreateNamespace=true"
      ]

      managed_namespace_metadata {
        labels = {
          "control-plane"           = "kserve-controller-manager"
          "controller-tools.k8s.io" = "1.0"
          "istio-injection"         = "disabled"
        }
      }
    }
  }

  depends_on = [
    resource.null_resource.dependencies
  ]
}

resource "null_resource" "this" {
  depends_on = [
    resource.argocd_application.this,
  ]
}

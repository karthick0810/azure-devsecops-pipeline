resource "azurerm_kubernetes_cluster" "example" {
  name                = "aks-prod-demo"
  location            = "eastus"
  resource_group_name = "rg-maingroup"

  dns_prefix          = "aks-prod-demo-dns"   # REQUIRED for imported cluster

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}

# ────────────────────────────────────────────────
# Fetch AKS kubeconfig for Kubernetes provider
# ────────────────────────────────────────────────

data "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  resource_group_name = var.aks_resource_group
}

provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.aks.kube_config[0].host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
}

# ────────────────────────────────────────────────
# 4 Environments
# ────────────────────────────────────────────────

locals {
  environments = ["sqa", "iuat", "uat", "prod"]
}

# ────────────────────────────────────────────────
# Create namespaces for each environment
# ────────────────────────────────────────────────

resource "kubernetes_namespace" "env_ns" {
  for_each = toset(local.environments)

  metadata {
    name = each.key
    labels = {
      environment = each.key
    }
  }
}

# ────────────────────────────────────────────────
# Deploy microservice to each environment
# ────────────────────────────────────────────────

resource "kubernetes_deployment" "app" {
  for_each = toset(local.environments)

  metadata {
    name      = "${var.app_name}-${each.key}"
    namespace = kubernetes_namespace.env_ns[each.key].metadata[0].name
    labels = {
      app = var.app_name
      env = each.key
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = var.app_name
        env = each.key
      }
    }

    template {
      metadata {
        labels = {
          app = var.app_name
          env = each.key
        }
      }

      spec {
        container {
          name  = var.app_name
          image = var.image

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

# ────────────────────────────────────────────────
# Service for each environment
# ────────────────────────────────────────────────

resource "kubernetes_service" "svc" {
  for_each = toset(local.environments)

  metadata {
    name      = "${var.app_name}-${each.key}-svc"
    namespace = kubernetes_namespace.env_ns[each.key].metadata[0].name
  }

  spec {
    selector = {
      app = var.app_name
      env = each.key
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}

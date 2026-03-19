resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.rg_name
  dns_prefix          = var.cluster_name

  default_node_pool {
    name           = "systempool"
    node_count     = 1
    vm_size        = "Standard_B2s" # 4GB RAM for System
    vnet_subnet_id = var.subnet_id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
  }
}

# Dedicated Pool for your SRE Tools (ELK/OTel)
resource "azurerm_kubernetes_cluster_node_pool" "monitoring" {
  name                  = "monitorpool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = var.monitoring_node_size # Use B2ms (8GB)
  node_count            = var.node_count
  vnet_subnet_id        = var.subnet_id

  node_labels = {
    "workload" = "monitoring"
  }
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}
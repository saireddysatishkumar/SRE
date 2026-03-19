terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "sre" {
  name     = var.resource_group_name
  location = var.location
}

# Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-sre-project"
  location            = azurerm_resource_group.sre.location
  resource_group_name = azurerm_resource_group.sre.name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "aks" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.sre.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.1.0/24"]
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-sre-lab"
  location            = azurerm_resource_group.sre.location
  resource_group_name = azurerm_resource_group.sre.name
  dns_prefix          = "aks-sre-lab"

  default_node_pool {
    name           = "systempool"
    node_count     = 1
    vm_size        = var.aks_node_size
    vnet_subnet_id = azurerm_subnet.aks.id # Direct reference, no module needed
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
  }
}

# Dedicated Pool for Monitoring (ELK/OTel)
resource "azurerm_kubernetes_cluster_node_pool" "monitoring" {
  name                  = "monitor"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = var.aks_node_size
  node_count            = var.node_count
  vnet_subnet_id        = azurerm_subnet.aks.id

  node_labels = { "role" = "monitoring" }
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}
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

resource "azurerm_resource_group" "sre" {
  name     = var.resource_group_name
  location = var.location
}

module "network" {
  source    = "../../modules/vnet"
  rg_name   = azurerm_resource_group.sre.name
  location  = azurerm_resource_group.sre.location
  vnet_name = "vnet-sre-project"
}

module "aks" {
  source               = "../../modules/aks"
  rg_name              = azurerm_resource_group.sre.name
  location             = azurerm_resource_group.sre.location
  cluster_name         = "aks-sre-lab"
  subnet_id            = module.network.subnet_id
  monitoring_node_size = var.aks_node_size
  node_count           = var.node_count
}
variable "rg_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "cluster_name" {
  type        = string
  description = "The name of the AKS cluster"
}

variable "subnet_id" {
  type        = string
  description = "The ID of the subnet where AKS will be deployed"
}


variable "node_count" {
  type        = number
  description = "Number of nodes in the monitoring pool"
}

variable "aks_node_size" {
  description = "The VM size for the AKS node pool"
  type        = string
  # No default here forces you to define it in your environment
}
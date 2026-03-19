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

variable "monitoring_node_size" {
  type        = string
  description = "VM size for the monitoring node pool"
}

variable "node_count" {
  type        = number
  description = "Number of nodes in the monitoring pool"
}
variable "resource_group_name" {
  default = "rg-sre-project"
}

variable "location" {
  default = "northeurope"
}

variable "aks_node_size" {
  default = "Standard_B2ms"
}

variable "node_count" {
  default = 1
}
variable "resource_group_name" { default = "rg-sre-project" }
variable "location"            { default = "East US" }
variable "aks_node_size"       { default = "Standard_B2ms" } # 8GB RAM
variable "node_count"          { default = 2 }
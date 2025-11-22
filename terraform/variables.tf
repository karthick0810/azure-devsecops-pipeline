variable "aks_cluster_name" {
  description = "Existing AKS cluster name"
  type        = string
  default     = "aks-prod-demo"
}

variable "aks_resource_group" {
  description = "Resource group of the existing AKS cluster"
  type        = string
  default     = "rg-maingroup"
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "image" {
  description = "Container image for all environments"
  type        = string
}

variable "app_name" {
  description = "Name of the microservice"
  type        = string
}

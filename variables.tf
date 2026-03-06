variable "primary_region" {
  type        = string
  description = "AWS region for the primary cluster"
}

variable "dr_region" {
  type        = string
  description = "AWS region for the DR cluster"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version for EKS clusters"
}

variable "velero_chart_version" {
  type        = string
  description = "Helm chart version for Velero"
}

variable "create_primary_cluster" {
  type        = bool
  description = "Toggle to create the Primary EKS Cluster"
  default     = true
}

variable "create_dr_cluster" {
  type        = bool
  description = "Toggle to create the DR EKS Cluster"
  default     = true
}
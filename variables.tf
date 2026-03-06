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
  description = "Kubernetes version (e.g., 1.31)"
}

variable "velero_chart_version" {
  type        = string
  description = "Helm chart version for Velero"
}
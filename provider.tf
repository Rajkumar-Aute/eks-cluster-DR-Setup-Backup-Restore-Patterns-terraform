terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws"
      version = "~> 6.0"
    }
    helm = { source = "hashicorp/helm"
      version = "~> 2.15"
    }
    kubernetes = { source = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
  }
}

provider "aws" {
  region = var.primary_region
}

provider "aws" {
  region = var.primary_region
  alias  = "primary"
}

provider "aws" {
  region = var.dr_region
  alias  = "dr"
}

# Primary Kubernetes Provider
provider "kubernetes" {
  alias                  = "primary"
  host                   = try(module.eks_primary[0].cluster_endpoint, "https://localhost")
  cluster_ca_certificate = try(base64decode(module.eks_primary[0].cluster_certificate_authority_data), "")
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", try(module.eks_primary[0].cluster_name, ""), "--region", var.primary_region]
  }
}

provider "kubernetes" {
  alias                  = "dr"
  host                   = try(module.eks_dr[0].cluster_endpoint, "https://localhost")
  cluster_ca_certificate = try(base64decode(module.eks_dr[0].cluster_certificate_authority_data), "")
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", try(module.eks_dr[0].cluster_name, ""), "--region", var.dr_region]
  }
}

provider "helm" {
  alias = "primary"
  kubernetes {
    host                   = try(module.eks_primary[0].cluster_endpoint, "https://localhost")
    cluster_ca_certificate = try(base64decode(module.eks_primary[0].cluster_certificate_authority_data), "")
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", try(module.eks_primary[0].cluster_name, ""), "--region", var.primary_region]
    }
  }
}

provider "helm" {
  alias = "dr"
  kubernetes {
    host                   = try(module.eks_dr[0].cluster_endpoint, "https://localhost")
    cluster_ca_certificate = try(base64decode(module.eks_dr[0].cluster_certificate_authority_data), "")
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", try(module.eks_dr[0].cluster_name, ""), "--region", var.dr_region]
    }
  }
}
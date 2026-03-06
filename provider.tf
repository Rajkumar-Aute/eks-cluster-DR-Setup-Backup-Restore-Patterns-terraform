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
  host                   = module.eks_primary.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_primary.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks_primary.cluster_name, "--region", var.primary_region]
  }
}

provider "kubernetes" {
  alias = "dr"
  host                   = module.eks_dr.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_dr.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # Ensure this matches the correct output attribute (cluster_name for v21)
    args = ["eks", "get-token", "--cluster-name", module.eks_dr.cluster_name, "--region", var.dr_region]
  }
}

provider "helm" {
  alias = "primary"
  kubernetes {
    host                   = module.eks_primary.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_primary.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks_primary.cluster_name, "--region", var.primary_region]
    }
  }
}

provider "helm" {
  alias = "dr"
  kubernetes {
    host                   = module.eks_dr.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_dr.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks_dr.cluster_name, "--region", var.dr_region]
    }
  }
}
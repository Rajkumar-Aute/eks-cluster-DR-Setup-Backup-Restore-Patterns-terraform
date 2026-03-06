module "vpc_primary" {
  source             = "terraform-aws-modules/vpc/aws"
  version            = "~> 5.0"
  providers          = { aws = aws.primary }
  name               = "primary-vpc"
  cidr               = "10.1.0.0/16"
  azs                = ["${var.primary_region}a", "${var.primary_region}b", "${var.primary_region}c"]
  private_subnets    = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  public_subnets     = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]
  enable_nat_gateway = true
}

module "eks_primary" {
  source             = "terraform-aws-modules/eks/aws"
  version            = "~> 21.0"
  providers          = { aws = aws.primary }
  name               = "primary-cluster"
  kubernetes_version = var.kubernetes_version
  vpc_id             = module.vpc_primary.vpc_id
  subnet_ids         = module.vpc_primary.private_subnets
  enable_irsa        = false # Pod Identity used instead

  # Ensure Pod Identity Agent is installed
  addons = {
    eks-pod-identity-agent = { most_recent = true }
  }

  eks_managed_node_groups = {
    core = { instance_types = ["t3.large"], min_size = 2, max_size = 4, desired_size = 2 }
  }
}

resource "aws_eks_pod_identity_association" "velero_primary" {
  provider        = aws.primary
  cluster_name    = module.eks_primary.cluster_name
  namespace       = "velero"
  service_account = "velero-server"
  role_arn        = aws_iam_role.velero_shared_role.arn
}
data "aws_vpc" "primary_default" {
  provider = aws.primary
  default  = true
}

data "aws_subnets" "primary_default" {
  provider = aws.primary
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.primary_default.id]
  }

  # Filter to only include subnets in zones a, b, and c
  filter {
    name   = "availability-zone"
    values = ["${var.primary_region}a", "${var.primary_region}b", "${var.primary_region}c"]
  }
}

module "eks_primary" {
  source             = "terraform-aws-modules/eks/aws"
  version            = "~> 21.0"
  count              = var.create_primary_cluster ? 1 : 0
  providers          = { aws = aws.primary }
  name               = "primary-cluster"
  kubernetes_version = var.kubernetes_version
  vpc_id             = data.aws_vpc.primary_default.id
  subnet_ids         = data.aws_subnets.primary_default.ids
  enable_irsa        = false
  enable_cluster_creator_admin_permissions = true
  upgrade_policy = {
    support_type = "STANDARD"
  }
  addons = {
    eks-pod-identity-agent = { most_recent = true }
  }

  eks_managed_node_groups = {
    core = {
      name           = "spot-node-group"
      capacity_type  = "SPOT"
      instance_types = ["t3.medium"]
      min_size       = 1
      max_size       = 1
      desired_size   = 1
      enable_bootstrap_user_data = true
      enable_public_ip          = true
      cluster_endpoint_public_access = true
    }
  }
}

resource "aws_eks_pod_identity_association" "velero_primary" {
  count           = var.create_primary_cluster ? 1 : 0
  provider        = aws.primary
  cluster_name    = module.eks_primary[0].cluster_name
  namespace       = "velero"
  service_account = "velero-server"
  role_arn        = aws_iam_role.velero_shared_role.arn
  depends_on      = [module.eks_primary]
}
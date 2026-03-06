# Declare the Default VPC for the DR Region
data "aws_vpc" "dr_default" {
  provider = aws.dr
  default  = true
}

# Fetch subnets and filter to avoid unsupported EKS zones
data "aws_subnets" "dr_default" {
  provider = aws.dr
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.dr_default.id]
  }

  # Filter to only include subnets in zones a, b, and c
  filter {
    name   = "availability-zone"
    values = ["${var.dr_region}a", "${var.dr_region}b", "${var.dr_region}c"]
  }
}

module "eks_dr" {
  source             = "terraform-aws-modules/eks/aws"
  version            = "~> 21.0"
  count              = var.create_dr_cluster ? 1 : 0
  providers          = { aws = aws.dr }
  name               = "dr-cluster"
  kubernetes_version = var.kubernetes_version
  vpc_id             = data.aws_vpc.dr_default.id
  subnet_ids         = data.aws_subnets.dr_default.ids
  enable_irsa        = false
  enable_cluster_creator_admin_permissions = true

  addons = {
    eks-pod-identity-agent = { most_recent = true }
  }

  eks_managed_node_groups = {
    core = {
      capacity_type  = "SPOT"
      instance_types = ["t3.medium"]
      min_size       = 1
      max_size       = 1
      desired_size   = 1
    }
  }
}

resource "aws_eks_pod_identity_association" "velero_dr" {
  count           = var.create_dr_cluster ? 1 : 0
  provider        = aws.dr
  cluster_name    = module.eks_dr[0].cluster_name
  namespace       = "velero"
  service_account = "velero-server"
  role_arn        = aws_iam_role.velero_shared_role.arn
}

# Mapping StorageClasses for 2026 Restores
resource "kubernetes_config_map" "velero_mapping" {
  count    = var.create_dr_cluster ? 1 : 0
  provider = kubernetes.dr
  metadata {
    name      = "change-storage-class-config"
    namespace = "velero"
    labels    = { "velero.io/plugin-config" = "", "velero.io/change-storage-class" = "RestoreItemAction" }
  }
  data = { "gp2" = "gp3" } # Maps primary SC to DR SC
  depends_on = [
    module.eks_primary,
    aws_eks_pod_identity_association.velero_primary
  ]
}
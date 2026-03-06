module "vpc_dr" {
  source             = "terraform-aws-modules/vpc/aws"
  version            = "~> 5.0"
  providers          = { aws = aws.dr }
  name               = "dr-vpc"
  cidr               = "10.2.0.0/16"
  azs                = ["${var.dr_region}a", "${var.dr_region}b", "${var.dr_region}c"]
  private_subnets    = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
  public_subnets     = ["10.2.101.0/24", "10.2.102.0/24", "10.2.103.0/24"]
  enable_nat_gateway = true
}

module "eks_dr" {
  source             = "terraform-aws-modules/eks/aws"
  version            = "~> 21.0"
  providers          = { aws = aws.dr }
  name               = "dr-cluster"
  kubernetes_version = var.kubernetes_version
  vpc_id             = module.vpc_dr.vpc_id
  subnet_ids         = module.vpc_dr.private_subnets
  enable_irsa        = false

  addons = {
    eks-pod-identity-agent = { most_recent = true }
  }
}

resource "aws_eks_pod_identity_association" "velero_dr" {
  provider        = aws.dr
  cluster_name    = module.eks_dr.cluster_name
  namespace       = "velero"
  service_account = "velero-server"
  role_arn        = aws_iam_role.velero_shared_role.arn
}

# Mapping StorageClasses for 2026 Restores
resource "kubernetes_config_map" "velero_mapping" {
  provider = kubernetes.dr
  metadata {
    name      = "change-storage-class-config"
    namespace = "velero"
    labels    = { "velero.io/plugin-config" = "", "velero.io/change-storage-class" = "RestoreItemAction" }
  }
  data = { "gp2" = "gp3" } # Maps primary SC to DR SC
}
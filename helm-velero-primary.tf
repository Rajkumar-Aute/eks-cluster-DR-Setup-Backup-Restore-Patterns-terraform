resource "helm_release" "velero_primary" {
  count            = var.create_primary_cluster ? 1 : 0
  provider         = helm.primary
  name             = "velero"
  repository       = "https://vmware-tanzu.github.io/helm-charts"
  chart            = "velero"
  namespace        = "velero"
  create_namespace = true
  version          = var.velero_chart_version

  values = [
    yamlencode({
      initContainers = [
        {
          name         = "velero-plugin-for-aws"
          image        = "velero/velero-plugin-for-aws:v1.9.0"
          volumeMounts = [{ mountPath = "/target", name = "plugins" }]
        }
      ]
      serviceAccount = {
        server = {
          create = true
          name   = "velero-server"
          # No annotation needed here because we use Pod Identity Association
        }
      }
      configuration = {
        backupStorageLocation = [{
          name     = "default"
          provider = "aws"
          bucket   = aws_s3_bucket.velero_dr_backups.id
          config   = { region = var.dr_region }
        }]
        volumeSnapshotLocation = [{
          name     = "default"
          provider = "aws"
          config   = { region = var.primary_region }
        }]
      }
      schedules = {
        prod-backup = {
          schedule = "*/15 * * * *"
          template = {
            includeClusterResources = true
            ttl                     = "720h0m0s"
          }
        }
      }
    })
  ]
  depends_on = [
    module.eks_primary,
    aws_eks_pod_identity_association.velero_primary
  ]
}
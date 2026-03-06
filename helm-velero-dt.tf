resource "helm_release" "velero_dr" {
  provider         = helm.dr
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
        }
      }
      configuration = {
        backupStorageLocation = [{
          name       = "default"
          provider   = "aws"
          bucket     = aws_s3_bucket.velero_dr_backups.id
          accessMode = "ReadOnly" # Essential DR Safety
          config     = { region = var.dr_region }
        }]
      }
    })
  ]
}
primary_region       = "us-east-1"
dr_region            = "us-east-2"
kubernetes_version   = "1.35"
velero_chart_version = "7.2.2"

# Flip these to true or false to create/destroy specific clusters
create_primary_cluster = true
create_dr_cluster      = true

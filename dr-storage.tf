resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "aws_s3_bucket" "velero_dr_backups" {
  provider      = aws.dr
  bucket        = "devsecops-eks-dr-backups-${random_string.suffix.result}"
  force_destroy = false
}

resource "aws_s3_bucket_public_access_block" "velero_s3_lock" {
  provider                = aws.dr
  bucket                  = aws_s3_bucket.velero_dr_backups.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "velero_v" {
  provider = aws.dr
  bucket   = aws_s3_bucket.velero_dr_backups.id
  versioning_configuration { status = "Enabled" }
}
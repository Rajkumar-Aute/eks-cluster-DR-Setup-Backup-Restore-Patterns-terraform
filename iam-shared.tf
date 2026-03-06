data "aws_iam_policy_document" "velero_trust" {
  statement {
    actions = ["sts:AssumeRole", "sts:TagSession"]
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"] # Modern 2026 Trust Policy
    }
  }
}

resource "aws_iam_role" "velero_shared_role" {
  name               = "velero-multi-region-dr-role"
  assume_role_policy = data.aws_iam_policy_document.velero_trust.json
}

resource "aws_iam_role_policy_attachment" "velero_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess" # Restrict this in Prod
  role       = aws_iam_role.velero_shared_role.name
}
# =============================================================
# KMS Keys — one per resource type, 90-day rotation
# =============================================================

data "aws_caller_identity" "current" {}

# ── EC2 / EBS ─────────────────────────────────────────────
resource "aws_kms_key" "ec2_key" {
  description             = "KMS key for EC2 EBS volume encryption"
  enable_key_rotation     = true
  rotation_period_in_days = 90
  deletion_window_in_days = 10

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowEC2Service"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowAutoScalingService"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey",
          "kms:CreateGrant",
          "kms:ReEncrypt*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = { Name = "${var.vpc_name}-ec2-kms-key" }
}

resource "aws_kms_alias" "ec2_key" {
  name          = "alias/${var.vpc_name}-ec2-key"
  target_key_id = aws_kms_key.ec2_key.key_id
}

# ── RDS ───────────────────────────────────────────────────
resource "aws_kms_key" "rds_key" {
  description             = "KMS key for RDS storage encryption"
  enable_key_rotation     = true
  rotation_period_in_days = 90
  deletion_window_in_days = 10

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowRDSService"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
      }
    ]
  })

  tags = { Name = "${var.vpc_name}-rds-kms-key" }
}

resource "aws_kms_alias" "rds_key" {
  name          = "alias/${var.vpc_name}-rds-key"
  target_key_id = aws_kms_key.rds_key.key_id
}

# ── S3 ────────────────────────────────────────────────────
resource "aws_kms_key" "s3_key" {
  description             = "KMS key for S3 bucket encryption"
  enable_key_rotation     = true
  rotation_period_in_days = 90
  deletion_window_in_days = 10

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowS3Service"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = { Name = "${var.vpc_name}-s3-kms-key" }
}

resource "aws_kms_alias" "s3_key" {
  name          = "alias/${var.vpc_name}-s3-key"
  target_key_id = aws_kms_key.s3_key.key_id
}

# ── Secrets Manager ───────────────────────────────────────
resource "aws_kms_key" "secrets_manager_key" {
  description             = "KMS key for Secrets Manager (DB password + email credentials)"
  enable_key_rotation     = true
  rotation_period_in_days = 90
  deletion_window_in_days = 10

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowSecretsManagerService"
        Effect = "Allow"
        Principal = {
          Service = "secretsmanager.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowEC2RoleToDecrypt"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.webapp_ec2_role.arn
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = { Name = "${var.vpc_name}-secrets-manager-kms-key" }
}

resource "aws_kms_alias" "secrets_manager_key" {
  name          = "alias/${var.vpc_name}-secrets-manager-key"
  target_key_id = aws_kms_key.secrets_manager_key.key_id
}
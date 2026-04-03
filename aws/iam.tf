# ─── IAM Role for EC2 (trust policy) ───

resource "aws_iam_role" "webapp_ec2_role" {
  name = "${var.vpc_name}-webapp-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.vpc_name}-webapp-ec2-role"
  }
}

# ─── IAM Policy: S3 access scoped to syllabus bucket only ───

resource "aws_iam_policy" "webapp_s3_policy" {
  name        = "${var.vpc_name}-webapp-s3-policy"
  description = "Allow EC2 to put, get, delete objects in the syllabus S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3ObjectOperations"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.syllabus.arn}/*"
      },
      {
        Sid    = "AllowS3BucketList"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.syllabus.arn
      }
    ]
  })
}

# ─── Attach S3 policy to role ───

resource "aws_iam_role_policy_attachment" "webapp_s3_attach" {
  role       = aws_iam_role.webapp_ec2_role.name
  policy_arn = aws_iam_policy.webapp_s3_policy.arn
}

# ─── Attach CloudWatch Agent policy to role ───

resource "aws_iam_role_policy_attachment" "webapp_cloudwatch_attach" {
  role       = aws_iam_role.webapp_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# ─── Instance Profile ───

resource "aws_iam_instance_profile" "webapp_profile" {
  name = "${var.vpc_name}-webapp-instance-profile"
  role = aws_iam_role.webapp_ec2_role.name
}

# ─── SNS Publish Policy for EC2 ───
# Add this to allow your web app (EC2) to publish to SNS

resource "aws_iam_policy" "webapp_sns_policy" {
  name        = "${var.vpc_name}-webapp-sns-policy"
  description = "Allow EC2 to publish messages to SNS topic"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowSNSPublish"
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = aws_sns_topic.user_verification.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "webapp_sns_attach" {
  role       = aws_iam_role.webapp_ec2_role.name
  policy_arn = aws_iam_policy.webapp_sns_policy.arn
}

# ─── IAM Role for Lambda ───

resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.vpc_name}-lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.vpc_name}-lambda-exec-role"
  }
}

# ─── IAM Policy for Lambda (least privilege) ───

resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.vpc_name}-lambda-policy"
  description = "Allow Lambda to write logs, send email via SES, and access DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:log-group:/aws/lambda/*"
      },
      {
        Sid    = "AllowDynamoDB"
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem"
        ]
        Resource = aws_dynamodb_table.email_tracking.arn
      },
      {
        Sid      = "AllowSES"
        Effect   = "Allow"
        Action   = ["ses:SendEmail", "ses:SendRawEmail"]
        Resource = "*"
        //Resource = "arn:aws:ses:${var.aws_region}:*:identity/${var.domain_name}"
      }
    ]
  })
}

# ─── Attach Lambda Policy to Lambda Role ───

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# ─── IAM Policy: Secrets Manager access for EC2 ───

resource "aws_iam_policy" "webapp_secrets_policy" {
  name        = "${var.vpc_name}-webapp-secrets-policy"
  description = "Allow EC2 to read DB password from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadSecrets"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          aws_secretsmanager_secret.db_password.arn,
          aws_secretsmanager_secret.email_credentials.arn
        ]
      },
      {
        Sid    = "UseKMSForSecrets"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.secrets_manager_key.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "webapp_secrets_attach" {
  role       = aws_iam_role.webapp_ec2_role.name
  policy_arn = aws_iam_policy.webapp_secrets_policy.arn
}
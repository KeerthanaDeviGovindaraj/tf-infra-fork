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

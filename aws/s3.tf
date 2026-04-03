# ─── S3 Bucket (UUID name, private, encrypted, lifecycle) ───

resource "random_uuid" "s3_bucket_name" {}

resource "aws_s3_bucket" "syllabus" {
  bucket        = random_uuid.s3_bucket_name.result
  force_destroy = true # Allow terraform destroy even if bucket is not empty

  tags = {
    Name = "${var.vpc_name}-syllabus-bucket"
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "syllabus" {
  bucket = aws_s3_bucket.syllabus.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Default encryption (AES-256)
resource "aws_s3_bucket_server_side_encryption_configuration" "syllabus" {
  bucket = aws_s3_bucket.syllabus.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_key.arn
    }
    bucket_key_enabled = true
  }
}

# Lifecycle policy: STANDARD -> STANDARD_IA after 30 days
resource "aws_s3_bucket_lifecycle_configuration" "syllabus" {
  bucket = aws_s3_bucket.syllabus.id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    filter {
      prefix = ""
    }
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}
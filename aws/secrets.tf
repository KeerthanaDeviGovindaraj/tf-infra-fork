# =============================================================
# Secrets Manager — DB Password & Email Credentials
# =============================================================

# ── Auto-generate DB password ─────────────────────────────
resource "random_password" "db_password" {
  length           = 16
  special          = false
}

# ── Store DB password in Secrets Manager ──────────────────
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.vpc_name}/db-password"
  kms_key_id              = aws_kms_key.secrets_manager_key.arn
  recovery_window_in_days = 0

  tags = { Name = "${var.vpc_name}-db-password-secret" }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
}

# ── Store Email credentials in Secrets Manager ────────────
resource "aws_secretsmanager_secret" "email_credentials" {
  name                    = "${var.vpc_name}/email-credentials"
  kms_key_id              = aws_kms_key.secrets_manager_key.arn
  recovery_window_in_days = 0

  tags = { Name = "${var.vpc_name}-email-credentials-secret" }
}

resource "aws_secretsmanager_secret_version" "email_credentials" {
  secret_id = aws_secretsmanager_secret.email_credentials.id
  secret_string = jsonencode({
    from_email = var.ses_from_email
    region     = var.aws_region
  })
}
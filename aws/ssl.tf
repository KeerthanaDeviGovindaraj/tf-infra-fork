# =============================================================
# SSL/TLS — ACM Certificate + HTTPS Listener
# DEV:  certificate auto-created via ACM DNS validation
# DEMO: certificate imported manually, ARN passed via tfvars
# =============================================================

# ── Create ACM cert (DEV only — skipped if acm_certificate_arn is set) ──
resource "aws_acm_certificate" "webapp" {
  count             = var.acm_certificate_arn == "" ? 1 : 0
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.vpc_name}-acm-cert"
  }
}

# ── DNS validation record (DEV only) ──────────────────────
resource "aws_route53_record" "cert_validation" {
  for_each = var.acm_certificate_arn == "" ? {
    for dvo in aws_acm_certificate.webapp[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  } : {}

  zone_id = var.route53_zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

# ── Wait for certificate validation (DEV only) ────────────
resource "aws_acm_certificate_validation" "webapp" {
  count                   = var.acm_certificate_arn == "" ? 1 : 0
  certificate_arn         = aws_acm_certificate.webapp[0].arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}

# ── Resolve the final certificate ARN ─────────────────────
locals {
  # DEV: use the ACM-created cert
  # DEMO: use the imported cert ARN from tfvars
  certificate_arn = var.acm_certificate_arn != "" ? var.acm_certificate_arn : aws_acm_certificate_validation.webapp[0].certificate_arn
}

# ── HTTPS listener on port 443 ─────────────────────────────
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.webapp.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = local.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webapp.arn
  }
}
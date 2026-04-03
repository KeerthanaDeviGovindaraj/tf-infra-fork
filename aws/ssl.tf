# =============================================================
# SSL/TLS — ACM Certificate + HTTPS Listener (DEV)
# =============================================================

# ── Request ACM certificate via DNS validation ─────────────
resource "aws_acm_certificate" "webapp" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.vpc_name}-acm-cert"
  }
}

# ── DNS validation record in Route53 ──────────────────────
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.webapp.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = "Z04656191C89OSEWJWNC8"
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

# ── Wait for certificate validation ───────────────────────
resource "aws_acm_certificate_validation" "webapp" {
  certificate_arn         = aws_acm_certificate.webapp.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}

# ── HTTPS listener on port 443 ─────────────────────────────
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.webapp.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.webapp.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webapp.arn
  }
}
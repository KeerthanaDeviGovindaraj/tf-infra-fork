# ─── A Record: alias to Load Balancer ───

resource "aws_route53_record" "webapp" {
  zone_id = "Z04656191C89OSEWJWNC8"
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.webapp.dns_name
    zone_id                = aws_lb.webapp.zone_id
    evaluate_target_health = true
  }
}

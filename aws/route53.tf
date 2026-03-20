# ─── A Record: alias to Load Balancer (replaces EC2 IP) ───

resource "aws_route53_record" "webapp" {
  zone_id = "Z0236480I4IHQA32188"
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.webapp.dns_name
    zone_id                = aws_lb.webapp.zone_id
    evaluate_target_health = true
  }
}
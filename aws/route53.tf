# ─── Data source: look up the hosted zone for dev subdomain ───

data "aws_route53_zone" "dev" {
  name         = var.domain_name
  private_zone = false
}

# ─── A Record: point domain to EC2 instance ───

resource "aws_route53_record" "webapp" {
  zone_id = data.aws_route53_zone.dev.zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 60
  records = [aws_instance.webapp.public_ip]
}

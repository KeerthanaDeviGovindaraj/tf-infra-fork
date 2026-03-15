# ─── A Record: point domain to EC2 instance ───

resource "aws_route53_record" "webapp" {
  zone_id = "Z0236480I4IHQA32188"
  name    = var.domain_name
  type    = "A"
  ttl     = 60
  records = [aws_instance.webapp.public_ip]
}

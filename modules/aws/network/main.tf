resource "aws_route53_zone" "main" {
  name = "mybank.com"
}

resource "aws_route53_record" "main-ns" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "mybank.com"
  type    = "NS"
  ttl     = "30"
  records = aws_route53_zone.main.name_servers
}
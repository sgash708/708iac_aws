variable "service_name" {}
variable "domain_name" {}

resource "aws_acm_certificate" "global" {
  domain_name       = "*.${var.domain_name}"
  validation_method = "DNS"

  subject_alternative_names = ["*.t.${var.domain_name}"]

  tags = {
    Name         = "use1-${var.service_name}ACM"
    service_name = var.service_name
  }

  lifecycle {
    # i dont need same acm
    create_before_destroy = true
  }
}
# Route53
data "aws_route53_zone" "default" {
  name         = var.domain_name
  private_zone = false
}
resource "aws_route53_record" "global" {
  for_each = {
    for acmg in aws_acm_certificate.global.domain_validation_options : acmg.domain_name => {
      name   = acmg.resource_record_name
      record = acmg.resource_record_value
      type   = acmg.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.default.zone_id
}
# validation
resource "aws_acm_certificate_validation" "global" {
  certificate_arn         = aws_acm_certificate.global.arn
  validation_record_fqdns = [for record in aws_route53_record.global : record.fqdn]
}
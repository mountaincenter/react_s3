#===================
# s3
#===================

resource "aws_s3_bucket" "cloudfront_logs" {
  bucket        = "${local.fqdn.web_name}-cloudfront-logs"
  force_destroy = true
}

#===================
# s3
#===================

resource "aws_s3_bucket" "web" {
  bucket        = local.bucket.name
  force_destroy = true
}

resource "aws_s3_bucket_website_configuration" "web" {
  bucket = aws_s3_bucket.web.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }

}

resource "aws_s3_bucket_versioning" "web" {
  bucket = aws_s3_bucket.web.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_acl" "web" {
  bucket = aws_s3_bucket.web.id
  acl    = "private"
}

resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.web.id
  policy = data.aws_iam_policy_document.s3_policy.json
}



# resource "aws_s3_bucket_public_access_block" "web" {
#   bucket                  = aws_s3_bucket.web.id
#   block_public_acls       = false
#   block_public_policy     = false
#   ignore_public_acls      = false
#   restrict_public_buckets = false
# }


# resource "aws_s3_object" "main" {
#   bucket       = aws_s3_bucket.web.id
#   key          = "index.html"
#   source       = "../index.html"
#   content_type = "text/html"
#   etag         = filemd5("../index.html")
# }


module "distribution_files" {
  source   = "hashicorp/dir/template"
  base_dir = "../frontend/react-app/build"
}

resource "aws_s3_object" "multiple_objects" {
  for_each     = module.distribution_files.files
  bucket       = aws_s3_bucket.web.id
  key          = each.key
  source       = each.value.source_path
  content_type = each.value.content_type
  etag         = filemd5(each.value.source_path)
}

#===================
# acm
#===================

resource "aws_acm_certificate" "main" {
  provider          = aws.virginia
  domain_name       = local.fqdn.web_name
  validation_method = "DNS"
}

resource "aws_acm_certificate_validation" "main" {
  provider                = aws.virginia
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.main_amc_c : record.fqdn]
}

#===================
# route53 acm
#===================

resource "aws_route53_record" "main_amc_c" {
  for_each = {
    for d in aws_acm_certificate.main.domain_validation_options : d.domain_name => {
      name   = d.resource_record_name
      record = d.resource_record_value
      type   = d.resource_record_type
    }
  }
  zone_id         = data.aws_route53_zone.naked.id
  name            = each.value.name
  type            = each.value.type
  ttl             = 172800
  records         = [each.value.record]
  allow_overwrite = true
}

#===================
# route53 record
#===================

resource "aws_route53_record" "main" {
  zone_id = data.aws_route53_zone.naked.id
  type    = "A"
  name    = local.fqdn.web_name
  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = true
  }
}

#===================
# cloudfront
#===================

resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = [local.fqdn.web_name]
  origin {
    origin_id                = aws_s3_bucket.web.id
    domain_name              = aws_s3_bucket.web.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.main.id
  }
  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = aws_acm_certificate.main.id
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }

  retain_on_delete = false

  logging_config {
    include_cookies = true
    bucket          = "${aws_s3_bucket.cloudfront_logs.id}.s3.amazonaws.com"
    prefix          = "log/"
  }

  default_cache_behavior {
    target_origin_id       = aws_s3_bucket.web.id
    viewer_protocol_policy = "redirect-to-https"
    cached_methods         = ["GET", "HEAD"]
    allowed_methods        = ["GET", "HEAD"]
    forwarded_values {
      query_string = false
      headers      = []
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["JP"]
    }
  }
}

resource "aws_cloudfront_origin_access_control" "main" {
  name                              = "cf-oac-with-tf-example"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

data "aws_route53_zone" "naked" {
  name = var.domain_name
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.web.arn}/*"]

    principals {
      identifiers = ["cloudfront.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_cloudfront_cache_policy" "managed_caching_optimized" {
  name = "Managed-CachingOptimized"
}
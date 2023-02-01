#===================
# s3
#===================

resource "aws_s3_bucket" "web" {
  bucket        = "test-react-yam"
  force_destroy = true
  policy = templatefile("bucket-policy.json", {
    "bucket_name" = "test-react-yam"
  })
  versioning {
    enabled = true
  }
  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

resource "aws_s3_bucket_acl" "web" {
  bucket = aws_s3_bucket.web.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "web" {
  bucket                  = aws_s3_bucket.web.id
  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

# resource "aws_s3_bucket_policy" "main" {
#   bucket = aws_s3_bucket.web.id
#   policy = data.aws_iam_policy_document.s3_policy.json
# }

resource "aws_s3_object" "main" {
  bucket       = aws_s3_bucket.web.id
  key          = "index.html"
  source       = "../index.html"
  content_type = "text/html"
  etag         = filemd5("../index.html")
}


# module "distribution_files" {
#   source   = "hashicorp/dir/template"
#   base_dir = "../frontend/react-app/build"
# }

# resource "aws_s3_object" "multiple_objects" {
#   for_each     = module.distribution_files.files
#   bucket       = aws_s3_bucket.web.id
#   key          = each.key
#   source       = each.value.source_path
#   content_type = each.value.source_path
#   etag         = filemd5(each.value.source_path)
# }
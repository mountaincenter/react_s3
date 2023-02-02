variable "bucket_name" {
  default = "test-react-yama"
}

variable "aws_region" {
  default = "ap-northeast-1"
}

variable "domain_name" {
  default = "ymnk.fun"
}

locals {
  fqdn = {
    web_name = "web.${var.domain_name}"
  }
  bucket = {
    name = local.fqdn.web_name
  }
}
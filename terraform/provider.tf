terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.49.0"
    }
  }
  required_version = "1.1.0"
}

provider "aws" {
  region = "ap-northeast-1"
}

provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}
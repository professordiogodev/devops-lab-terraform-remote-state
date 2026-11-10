terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # TODO (Part 2): the S3 backend goes here. Backend blocks cannot use variables.
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      lab = "terraform-remote-state"
    }
  }
}

# The thing under management: three Clippy settings kept in the AWS parameter store (free).
locals {
  settings = {
    max_url_length = "2048"
    code_length    = "6"
    cache_ttl      = "300"
  }
}

resource "aws_ssm_parameter" "clippy" {
  for_each = local.settings
  name     = "/clippy/staging/${each.key}"
  type     = "String"
  value    = each.value
}

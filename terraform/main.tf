terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
  }

  # TODO (Part 2): the S3 backend goes here. Backend blocks cannot use variables.
}

# Provided: your handle (your IAM user name, shortened). Everyone in this class shares one AWS account,
# so every resource is tagged with it and the checks only look at yours.
data "external" "me" {
  program = ["bash", "${path.module}/../.lab/handle.sh", "--json"]
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      lab     = "terraform-remote-state"
      student = data.external.me.result.student
    }
  }
}

# The thing under management: three Clippy settings kept in the AWS parameter store (free).
locals {
  student = data.external.me.result.student
  settings = {
    max_url_length = "2048"
    code_length    = "6"
    cache_ttl      = "300"
  }
}

resource "aws_ssm_parameter" "clippy" {
  for_each = local.settings
  name     = "/clippy/${local.student}/staging/${each.key}"
  type     = "String"
  value    = each.value
}

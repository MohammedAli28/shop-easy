terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "shop-easy-tf-state-bucket"
    key    = "state/terraform.tfstate"
    region = "us-east-1"
  }
}

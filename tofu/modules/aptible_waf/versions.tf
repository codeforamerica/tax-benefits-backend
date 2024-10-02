terraform {
  required_version = ">= 1.6"

  required_providers {
    aptible = {
      version = ">= 0.9"
      source  = "aptible/aptible"
    }

    aws = {
      version = ">= 5.44"
      source  = "hashicorp/aws"
    }
  }
}

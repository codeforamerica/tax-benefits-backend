terraform {
  required_version = ">= 1.6"

  required_providers {
    datadog = {
      source  = "DataDog/datadog"
      version = "~> 3.48"
    }
  }
}

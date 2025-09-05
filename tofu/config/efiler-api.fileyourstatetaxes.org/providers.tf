provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      project     = "efiler-api"
      environment = "production"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      project     = "gyr"
      environment = "demo"
    }
  }
}

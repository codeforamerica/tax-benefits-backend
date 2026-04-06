provider "aws" {
  region              = "us-east-1"
  allowed_account_ids = ["564912844385"]

  default_tags {
    tags = {
      project     = "gyraffe"
      environment = "heroku"
    }
  }
}

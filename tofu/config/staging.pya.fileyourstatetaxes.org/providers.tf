provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      project     = "pya"
      environment = "staging"
    }
  }
}

provider "aws" {
  alias  = "backup"
  region = "us-west-2"

  default_tags {
    tags = {
      project     = "pya"
      environment = "staging"
    }
  }
}

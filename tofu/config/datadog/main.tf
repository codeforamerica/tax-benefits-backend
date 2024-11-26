terraform {
  backend "s3" {
    bucket         = "tax-benefits-prod-tfstate"
    key            = "datadog.tfstate"
    region         = "us-east-1"
    dynamodb_table = "prod.tfstate"
  }
}

module "datadog" {
  source = "github.com/codeforamerica/tofu-modules-datadog-waf?ref=1.0.0"

  default_webacls = ["fyst-demo"]
  title          = "[TESTING] Web Application Firewall (WAF)"
}

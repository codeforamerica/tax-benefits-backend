terraform {
  backend "s3" {
    bucket         = "gyraffe-staging-tfstate"
    key            = "heroku.gyraffe.getyourrefund.org"
    region         = "us-east-1"
    dynamodb_table = "staging.tfstate"
  }
}

locals {
  schemas_bucket_name = "gyraffe-staging-schemas"
}

# IAM user for Heroku review apps to access the schemas S3 bucket.
resource "aws_iam_user" "heroku" {
  name = "gyraffe-heroku-schemas"
  path = "/heroku/"
}

resource "aws_iam_access_key" "heroku" {
  user = aws_iam_user.heroku.name
}

resource "aws_iam_user_policy" "heroku_schemas_read" {
  name = "gyraffe-heroku-schemas-read"
  user = aws_iam_user.heroku.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
        ]
        Resource = [
          "arn:aws:s3:::${local.schemas_bucket_name}",
          "arn:aws:s3:::${local.schemas_bucket_name}/*",
        ]
      }
    ]
  })
}

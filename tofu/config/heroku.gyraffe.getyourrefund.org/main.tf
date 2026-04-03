terraform {
  backend "s3" {
    bucket         = "gyraffe-staging-tfstate"
    key            = "heroku.gyraffe.getyourrefund.org"
    region         = "us-east-1"
    dynamodb_table = "staging.tfstate"
  }
}

locals {
  # This could be dynamically read via a terraform_remote_state data source,
  # but it shouldn't ever change so I'm leaving it hard-coded for now.
  schemas_bucket_name = "gyraffe-staging-schemas"
}

# IAM user for Heroku review apps to access the schemas S3 bucket.
# Manual step: Create an access key for this user and provide it to heroku review apps via env vars
#trivy:ignore:AVD-AWS-0143
resource "aws_iam_user" "heroku" {
  name = "gyraffe-heroku-schemas"
  path = "/heroku/"
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

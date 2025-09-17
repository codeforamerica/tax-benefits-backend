output "log_bucket" {
  description = "The Amazon S3 log_bucket to store log files."
  value       = module.logging.bucket
}

output "submission_pdf_bucket_name" {
  description = "S3 bucket where submission PDFs are stored"
  value = aws_s3_bucket.heroku_submission_pdfs.bucket
}

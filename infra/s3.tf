resource "aws_s3_bucket" "uploads" {
  bucket = var.bucket_name

  tags = {
    Project = var.project_tag
  }
}

resource "aws_s3_bucket_versioning" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_cors_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST"]
    allowed_origins = ["http://localhost:5173", "https://${aws_cloudfront_distribution.main.domain_name}"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3600
  }
}
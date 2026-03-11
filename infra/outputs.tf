output "bucket_name" {
  value = aws_s3_bucket.uploads.bucket
}

output "bucket_region" {
  value = var.aws_region
}

output "access_key_id" {
  value     = aws_iam_access_key.uploader.id
  sensitive = true
}

output "secret_access_key" {
  value     = aws_iam_access_key.uploader.secret
  sensitive = true
}
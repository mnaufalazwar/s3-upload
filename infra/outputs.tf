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

output "cloudfront_url" {
  description = "CloudFront distribution URL"
  value       = "https://${aws_cloudfront_distribution.main.domain_name}"
}

output "alb_dns" {
  description = "ALB DNS name"
  value       = aws_lb.main.dns_name
}

output "ecr_repository_url" {
  description = "ECR repository URL (for docker push)"
  value       = aws_ecr_repository.backend.repository_url
}

output "s3_bucket" {
  description = "Frontend S3 bucket name"
  value       = aws_s3_bucket.frontend.id
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (for cache invalidation)"
  value       = aws_cloudfront_distribution.main.id
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.backend.name
}
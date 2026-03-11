variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-southeast-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket (must be globally unique)"
  type        = string
}

variable "project_tag" {
  description = "Tag for all resources"
  type        = string
  default     = "capstone-tutorial"
}

variable "project_name" {
  description = "Project name used as prefix for all resources"
  type        = string
  default     = "capstone-tutorial"
}

variable "use_custom_domain" {
  description = "Set to true after DNS switch to add the custom domain alias to CloudFront and update CORS"
  type        = bool
  default     = false
}

variable "container_image" {
  description = "Docker image URI (set after first push to ECR)"
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN in us-east-1 for the custom domain (leave empty to use CloudFront default cert)"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Custom domain name (leave empty to use CloudFront default URL)"
  type        = string
  default     = ""
}
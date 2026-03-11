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
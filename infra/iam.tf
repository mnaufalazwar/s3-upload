resource "aws_iam_user" "uploader" {
  name = "${var.project_tag}-uploader"

  tags = {
    Project = var.project_tag
  }
}

resource "aws_iam_access_key" "uploader" {
  user = aws_iam_user.uploader.name
}

resource "aws_iam_user_policy" "uploader_policy" {
  name = "${var.project_tag}-upload-policy"
  user = aws_iam_user.uploader.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.uploads.arn,
          "${aws_s3_bucket.uploads.arn}/*"
        ]
      }
    ]
  })
}

//// ECS role for production deployment
// 1. Task Role -> access to S3
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_tag}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Project = var.project_tag
  }
}

resource "aws_iam_role_policy" "ecs_s3_access" {
  name = "${var.project_tag}-s3-access"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.uploads.arn,
          "${aws_s3_bucket.uploads.arn}/*"
        ]
      }
    ]
  })
}

// 2. Execution Role -> pull image from ECR
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.project_tag}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Project = var.project_tag
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
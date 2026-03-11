resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.project_name}-backend"
  retention_in_days = 30

  tags = { Name = "${var.project_name}-backend-logs" }
}

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  tags = { Name = "${var.project_name}-cluster" }
}

locals {
  # If no container image is specified yet, use a placeholder.
  # You'll update this after the first docker push.
  container_image = var.container_image != "" ? var.container_image : "${aws_ecr_repository.backend.repository_url}:latest"

  frontend_url = var.use_custom_domain ? "https://${var.domain_name}" : "https://${aws_cloudfront_distribution.main.domain_name}"
}

resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.project_name}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  // attach roles to ECS
  task_role_arn      = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([{
    name  = "${var.project_name}-backend"
    image = local.container_image

    portMappings = [{
      containerPort = 8000
      protocol      = "tcp"
    }]

    environment = [
        { name = "S3_BUCKET_NAME", value = var.bucket_name },
        { name = "AWS_REGION",     value = var.aws_region },
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.backend.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }

  }])

  tags = { Name = "${var.project_name}-backend" }
}

resource "aws_ecs_service" "backend" {
  name            = "${var.project_name}-backend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  enable_execute_command            = true
  health_check_grace_period_seconds = 300

  network_configuration {
    subnets          = [aws_subnet.public_1.id, aws_subnet.public_2.id]
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "${var.project_name}-backend"
    container_port   = 8000
  }

  depends_on = [aws_lb_listener.http]

  tags = { Name = "${var.project_name}-backend-service" }
}

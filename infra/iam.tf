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
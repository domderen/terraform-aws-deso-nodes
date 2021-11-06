resource "aws_cloudwatch_log_group" "backend" {
  name              = "${var.name}/backend"
  retention_in_days = 30

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "${var.name}/frontend"
  retention_in_days = 30

  tags = var.tags
}
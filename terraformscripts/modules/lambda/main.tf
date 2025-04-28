
variable "environment" {
  type = string
}

variable "sqs_queue_arn" {
  type = string
}

variable "sns_topic_arn" {
  type = string
}

# Lambda Role
resource "aws_iam_role" "lambda_role" {
  name_prefix = "${var.environment}-order-processor-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = {
    Environment = var.environment
    Name = "${var.environment}-order-processor"
  }
}

# Lambda Basic Execution Policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda Custom Policy
resource "aws_iam_role_policy" "lambda_policy" {
  name_prefix = "order-processor-"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          "arn:aws:dynamodb:us-west-2:615299759671:table/dev-orders",
          "arn:aws:dynamodb:us-west-2:615299759671:table/dev-orders/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = var.sqs_queue_arn
      },
      {
        Effect = "Allow"
        Action = ["sns:Publish"]
        Resource = [
          var.sns_topic_arn,
          "arn:aws:sns:us-west-2:615299759671:dev-order-events"
        ]
      }
    ]
  })
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.environment}-order-processor-v2"
  retention_in_days = 7

  tags = {
    Environment = var.environment
    Name        = "${var.environment}-order-processor-v2"
  }
}

# Lambda Function
resource "aws_lambda_function" "order_processor" {
  filename         = "${path.module}/function/order_processor.zip"
  source_code_hash = filebase64sha256("${path.module}/function/order_processor.zip")
  function_name    = "${var.environment}-order-processor-v2"
  role            = aws_iam_role.lambda_role.arn
  handler         = "order_processor.handler"
  runtime         = "python3.9"
  timeout         = 30
  memory_size     = 256

  environment {
    variables = {
      SNS_TOPIC_ARN = var.sns_topic_arn
      DYNAMODB_TABLE = "dev-orders"
      REGION        = "us-west-2"
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_logs,
    aws_iam_role_policy.lambda_policy,
    aws_iam_role_policy_attachment.lambda_basic
  ]
}

# Lambda Permission for SQS
resource "aws_lambda_permission" "sqs_invoke" {
  statement_id  = "AllowSQSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.order_processor.function_name
  principal     = "sqs.amazonaws.com"
  source_arn    = var.sqs_queue_arn
}

# Event Source Mapping
resource "aws_lambda_event_source_mapping" "order_processor" {
  event_source_arn = var.sqs_queue_arn
  function_name    = aws_lambda_function.order_processor.arn
  batch_size       = 5
  enabled          = true

  scaling_config {
    maximum_concurrency = 2
  }
}

output "function_name" {
  value = aws_lambda_function.order_processor.function_name
}

output "function_arn" {
  value = aws_lambda_function.order_processor.arn
}

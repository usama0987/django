variable "environment" {
  type        = string
  description = "Environment name (e.g., dev, staging, prod)"
}

# SNS Topics
resource "aws_sns_topic" "order_events" {
  name = "${var.environment}-order-events"
}

resource "aws_sns_topic" "order_completed" {
  name = "${var.environment}-order-completed"
}

# SQS Queues
resource "aws_sqs_queue" "order_processing" {
  name                       = "${var.environment}-order-processing"
  visibility_timeout_seconds = 300
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 20  # Enable long polling

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.order_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Environment = var.environment
  }
}

resource "aws_sqs_queue" "order_dlq" {
  name                      = "${var.environment}-order-dlq"
  message_retention_seconds = 1209600  # 14 days retention for DLQ

  tags = {
    Environment = var.environment
  }
}

# SQS Queue Policy
resource "aws_sqs_queue_policy" "order_processing" {
  queue_url = aws_sqs_queue.order_processing.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.order_processing.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.order_events.arn
          }
        }
      }
    ]
  })
}

# SNS Topic Subscription
resource "aws_sns_topic_subscription" "order_processing" {
  topic_arn = aws_sns_topic.order_events.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.order_processing.arn
}

# SNS Topic Policy with dynamic account ID reference
resource "aws_sns_topic_policy" "order_events" {
  arn = aws_sns_topic.order_events.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          AWS = "*"
        }
        Action    = "sns:Publish"
        Resource  = aws_sns_topic.order_events.arn
        Condition = {
          StringEquals = {
            "AWS:SourceOwner" = split(":", aws_sns_topic.order_events.arn)[4]
          }
        }
      }
    ]
  })
}

output "order_events_topic_arn" {
  description = "ARN of the order events SNS topic"
  value       = aws_sns_topic.order_events.arn
}

output "order_completed_topic_arn" {
  description = "ARN of the order completed SNS topic"
  value       = aws_sns_topic.order_completed.arn
}

output "order_processing_queue_arn" {
  description = "ARN of the order processing SQS queue"
  value       = aws_sqs_queue.order_processing.arn
}

output "order_processing_queue_url" {
  description = "URL of the order processing SQS queue"
  value       = aws_sqs_queue.order_processing.id
}

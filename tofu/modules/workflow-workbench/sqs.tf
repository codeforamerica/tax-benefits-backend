resource "aws_sqs_queue" "queue_to_dynamo" {
  name = "${local.name_prefix}-to-dynamodb"

  kms_master_key_id                 = local.kms_key_id
  kms_data_key_reuse_period_seconds = 300

  # Message retention and visibility
  message_retention_seconds  = 1209600  # 14 days
  visibility_timeout_seconds = 300      # 5 minutes

  # Dead letter queue for failed messages
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-to-dynamodb"
  })
}

resource "aws_sqs_queue" "dlq" {
  name = "${local.name_prefix}-to-dynamodb-dlq"

  kms_master_key_id                 = local.kms_key_id
  kms_data_key_reuse_period_seconds = 300

  # Longer retention for dead letter messages
  message_retention_seconds = 1209600  # 14 days

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-to-dynamodb-dlq"
  })
}

# Allow Lambda to receive messages from DLQ
resource "aws_sqs_queue_policy" "dlq" {
  queue_url = aws_sqs_queue.dlq.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sqs:SendMessage"
        Resource = aws_sqs_queue.dlq.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sqs_queue.queue_to_dynamo.arn
          }
        }
      }
    ]
  })
}
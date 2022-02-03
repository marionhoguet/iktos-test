#Aws key to encrypt logs
resource "aws_kms_key" "key" {
  description             = "kms key"
  enable_key_rotation     = true
  deletion_window_in_days = 7
}

#Create cloudwatch log group
resource "aws_cloudwatch_log_group" "application_log_group" {
  kms_key_id = aws_kms_key.key.arn
  name = "application_log_group"
}


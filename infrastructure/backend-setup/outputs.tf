# Backend Infrastructure Outputs

output "dev_s3_bucket" {
  description = "S3 bucket for dev environment state"
  value       = aws_s3_bucket.dev_state.bucket
}

output "dev_dynamodb_table" {
  description = "DynamoDB table for dev environment state locking"
  value       = aws_dynamodb_table.dev_locks.name
}


output "summary" {
  description = "Summary of created backend resources"
  value = {
    s3_buckets = {
      dev = aws_s3_bucket.dev_state.bucket
    }
    dynamodb_tables = {
      dev = aws_dynamodb_table.dev_locks.name
    }
  }
}

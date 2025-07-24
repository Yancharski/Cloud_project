# URL для вызова API Gateway
output "api_url" {
  description = "Invoke URL для доступа к REST API"
  value       = aws_api_gateway_stage.stage.invoke_url
}

# Имя созданной таблицы DynamoDB
output "dynamodb_table_name" {
  description = "Имя DynamoDB‑таблицы"
  value       = aws_dynamodb_table.items.name
}

# ARN Lambda‑функции
output "lambda_function_arn" {
  description = "ARN созданной Lambda‑функции"
  value       = aws_lambda_function.api_handler.arn
}

# ID REST API в API Gateway
output "api_id" {
  description = "ID REST API в API Gateway"
  value       = aws_api_gateway_rest_api.api.id
}

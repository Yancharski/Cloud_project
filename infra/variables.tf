# Регион AWS, в котором будут создаваться ресурсы
variable "region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"
}

# Имя таблицы DynamoDB
variable "table_name" {
  description = "Name of the DynamoDB table"
  type        = string
  default     = "items"
}

# Окружение (stage) для тегов, имён ресурсов и stage API Gateway
variable "env" {
  description = "Deployment environment (e.g., dev, prod)"
  type        = string
  default     = "dev"
}

# Имя Lambda-функции (будет суффиксировано значением var.env)
variable "lambda_function_name" {
  description = "Base name for the Lambda function"
  type        = string
  default     = "api-handler"
}

# Планируемые настройки памяти и таймаута для Lambda
variable "lambda_memory_size" {
  description = "Memory size (MB) for the Lambda function"
  type        = number
  default     = 128
}

variable "lambda_timeout" {
  description = "Timeout (seconds) for the Lambda function"
  type        = number
  default     = 10
}

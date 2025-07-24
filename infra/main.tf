terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

provider "aws" {
  region = var.region

  # Настройки для LocalStack
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    dynamodb   = "http://localhost:4566"
    lambda     = "http://localhost:4566"
    iam        = "http://localhost:4566"
    apigateway = "http://localhost:4566"
    sts        = "http://localhost:4566"
    cloudwatch = "http://localhost:4566"
  }
}

// 1. DynamoDB Table
resource "aws_dynamodb_table" "items" {
  name           = var.table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  attribute {
    name = "id"
    type = "S"
  }
  tags = {
    Environment = var.env
  }
}

// 2. IAM Role для Lambda
resource "aws_iam_role" "lambda_exec" {
  name               = "${var.env}-lambda-exec"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

// 3. IAM Policy для доступа к DynamoDB и CloudWatch
resource "aws_iam_role_policy" "lambda_policy" {
  name   = "${var.env}-lambda-policy"
  role   = aws_iam_role.lambda_exec.id
  policy = data.aws_iam_policy_document.lambda_policy.json
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:Scan",
      "dynamodb:Query"
    ]
    resources = [
      aws_dynamodb_table.items.arn,
      "${aws_dynamodb_table.items.arn}/*"
    ]
  }
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:${var.region}:*:*"]
  }
}

// 4. Lambda Function
resource "aws_lambda_function" "api_handler" {
  function_name = "${var.env}-api-handler"
  filename      = "${path.module}/../api/package.zip"     // zip с main.py, models.py, db.py и зависимостями
  handler       = "api.main.handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec.arn
  timeout       = 10
  memory_size   = 128

  environment {
    variables = {
      DYNAMODB_TABLE        = var.table_name
      AWS_REGION            = var.region
      DYNAMODB_ENDPOINT_URL = "http://host.docker.internal:4566"
      AWS_ACCESS_KEY_ID     = "test"
      AWS_SECRET_ACCESS_KEY = "test"
    }
  }
}

// 5. API Gateway REST API
resource "aws_api_gateway_rest_api" "api" {
  name        = "${var.env}-rest-api"
  description = "REST API для CRUD операций над items"
}

// 6. Root resource ID
data "aws_api_gateway_resource" "root" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  path        = "/"
}

// 7. Ресурс /items
resource "aws_api_gateway_resource" "items" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = data.aws_api_gateway_resource.root.id
  path_part   = "items"
}

// 8. Метод POST /items
resource "aws_api_gateway_method" "post_items" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.items.id
  http_method   = "POST"
  authorization = "NONE"
}

// 9. Интеграция POST -> Lambda
resource "aws_api_gateway_integration" "post_items_integration" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.items.id
  http_method = aws_api_gateway_method.post_items.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_handler.invoke_arn
}

// 10. Метод GET /items/{id}
resource "aws_api_gateway_resource" "item_id" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.items.id
  path_part   = "{item_id}"
}

resource "aws_api_gateway_method" "get_item" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.item_id.id
  http_method   = "GET"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.item_id" = true
  }
}

resource "aws_api_gateway_integration" "get_item_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.item_id.id
  http_method             = aws_api_gateway_method.get_item.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_handler.invoke_arn
  request_parameters = {
    "integration.request.path.item_id" = "method.request.path.item_id"
  }
}

// 11. Deployment и Stage
resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  depends_on = [
    aws_api_gateway_integration.post_items_integration,
    aws_api_gateway_integration.get_item_integration
  ]
}

resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = var.env
}

// 12. Разрешение вызова Lambda из API Gateway
resource "aws_lambda_permission" "allow_api" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

// 13. Outputs
output "api_endpoint" {
  description = "URL для доступа к API"
  value       = aws_api_gateway_stage.stage.invoke_url
}

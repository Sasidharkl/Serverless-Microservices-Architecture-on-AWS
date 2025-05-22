resource "aws_dynamodb_table" "user_table" {
  name         = "user-service-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy_attachment" "lambda_logs" {
  name       = "lambda_logs"
  roles      = [aws_iam_role.lambda_exec_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "user_lambda" {
  filename         = "../lambdas/user_service.zip"
  function_name    = "user-service-lambda"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "handler.lambda_handler"
  source_code_hash = filebase64sha256("../lambdas/user_service.zip")
  runtime          = "python3.11"
  timeout          = 10

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.user_table.name
    }
  }
}

resource "aws_apigatewayv2_api" "user_api" {
  name          = "user-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.user_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.user_lambda.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.user_api.id
  route_key = "POST /users"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "get_user" {
  api_id    = aws_apigatewayv2_api.user_api.id
  route_key = "GET /users/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.user_lambda.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.user_api.execution_arn}/*/*"
}

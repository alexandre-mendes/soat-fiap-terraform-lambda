resource "aws_lambda_function" "authenticator_lambda" {
  function_name = "LambdaAuthenticator"
  filename      = "${path.module}/lambda-authenticator.zip"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  source_code_hash = filebase64sha256("${path.module}/lambda-authenticator.zip")
  role          = var.existing_lambda_role_arn

  environment {
    variables = {
      JWT_SECRET     = var.jwt_secret
      CLIENTS_TABLE  = var.clients_table_name
    }
  }
}

resource "aws_apigatewayv2_api" "http_api" {
  name          = "fastfood-api"
  protocol_type = "HTTP"
}

resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.authenticator_lambda.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id             = aws_apigatewayv2_api.http_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.authenticator_lambda.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "post_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /auth"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

output "auth_api_url" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}

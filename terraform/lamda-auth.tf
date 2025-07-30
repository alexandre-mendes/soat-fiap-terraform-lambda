resource "aws_lambda_function" "authenticator_lambda" {
  function_name    = "LambdaAuthenticator"
  filename         = "${path.module}/lambda-authenticator.zip"
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  source_code_hash = filebase64sha256("${path.module}/lambda-authenticator.zip")
  role             = var.existing_lambda_role_arn

  environment {
    variables = {
      JWT_SECRET    = var.jwt_secret
      CLIENTS_TABLE = var.clients_table_name
    }
  }
}

resource "aws_apigatewayv2_api" "http_api" {
  name          = "fastfood-api"
  protocol_type = "HTTP"
}

resource "aws_lambda_permission" "apigw_invoke_authenticator" {
  statement_id  = "AllowAPIGatewayInvokeAuthenticator"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.authenticator_lambda.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.authenticator_lambda.invoke_arn
  integration_method     = "POST"
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

# authorizer

resource "aws_lambda_function" "authorizer_lambda" {
  function_name    = "LambdaAuthorizer"
  filename         = "${path.module}/lambda-authorizer.zip"
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  source_code_hash = filebase64sha256("${path.module}/lambda-authorizer.zip")
  role             = var.existing_lambda_role_arn

  environment {
    variables = {
      JWT_SECRET = var.jwt_secret
    }
  }
}

# PERMISSÃO PARA O API GATEWAY INVOCAR A LAMBDA AUTHORIZER
resource "aws_lambda_permission" "apigw_invoke_authorizer" {
  statement_id  = "AllowAPIGatewayInvokeAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.authorizer_lambda.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_authorizer" "lambda_authorizer" {
  name                              = "LambdaJWTAuthorizer"
  api_id                            = aws_apigatewayv2_api.http_api.id
  authorizer_type                   = "REQUEST"
  authorizer_uri                    = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.authorizer_lambda.arn}/invocations"
  identity_sources                  = ["$request.header.Authorization"]
  authorizer_payload_format_version = "2.0"
  enable_simple_responses           = true
  authorizer_result_ttl_in_seconds  = 0
}


# Integração para o Microsserviço de Cliente
resource "aws_apigatewayv2_integration" "customer_ms_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  integration_uri        = "http://${data.kubernetes_service.customer_ms_service.status[0].load_balancer[0].ingress[0].hostname}/{proxy}"
  payload_format_version = "1.0"
}

# Rota para o Microsserviço de Cliente (/costumer)
resource "aws_apigatewayv2_route" "customer_ms_route" {
  api_id             = aws_apigatewayv2_api.http_api.id
  route_key          = "ANY /api/costumers/{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.customer_ms_integration.id}"
  authorizer_id      = aws_apigatewayv2_authorizer.lambda_authorizer.id
  authorization_type = "CUSTOM"
}

# Integração para o Microsserviço de Pedidos
resource "aws_apigatewayv2_integration" "order_ms_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  integration_uri        = "http://${data.kubernetes_service.order_ms_service.status[0].load_balancer[0].ingress[0].hostname}/{proxy}"
  payload_format_version = "1.0"
}

# Rota para o Microsserviço de Pedidos (/order)
resource "aws_apigatewayv2_route" "order_ms_route" {
  api_id             = aws_apigatewayv2_api.http_api.id
  route_key          = "ANY /api/orders/{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.order_ms_integration.id}"
  authorizer_id      = aws_apigatewayv2_authorizer.lambda_authorizer.id
  authorization_type = "CUSTOM"
}

# Integração para o Microsserviço de Produto
resource "aws_apigatewayv2_integration" "product_ms_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  integration_uri        = "http://${data.kubernetes_service.product_ms_service.status[0].load_balancer[0].ingress[0].hostname}/{proxy}"
  payload_format_version = "1.0"
}

# Rota para o Microsserviço de Produto (/product)
resource "aws_apigatewayv2_route" "product_ms_route" {
  api_id             = aws_apigatewayv2_api.http_api.id
  route_key          = "ANY /api/products/{proxy+}" 
  target             = "integrations/${aws_apigatewayv2_integration.product_ms_integration.id}"
  authorizer_id      = aws_apigatewayv2_authorizer.lambda_authorizer.id
  authorization_type = "CUSTOM"
}
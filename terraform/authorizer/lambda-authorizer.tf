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

resource "aws_apigatewayv2_authorizer" "lambda_authorizer" {
  name                             = "LambdaJWTAuthorizer"
  api_id                           = aws_apigatewayv2_api.http_api.id
  authorizer_type                  = "REQUEST"
  authorizer_uri                   = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.authorizer_lambda.arn}/invocations"
  identity_sources                 = ["$request.header.Authorization"]
  authorizer_payload_format_version = "2.0"
  enable_simple_responses          = true
}

resource "aws_apigatewayv2_vpc_link" "pedido_vpc_link" {
  name = "fastfood-vpc-link"

  subnet_ids = [
    for subnet in data.aws_subnet.private_subnets :
    subnet.id if subnet.availability_zone != "${var.aws_region}e"
  ]

  security_group_ids = [data.aws_security_group.vpc_link_sg.id]
}

resource "aws_apigatewayv2_integration" "pedido_integration" {
  api_id                = aws_apigatewayv2_api.http_api.id
  integration_type      = "HTTP_PROXY"
  connection_type       = "VPC_LINK"
  connection_id         = aws_apigatewayv2_vpc_link.pedido_vpc_link.id
  integration_method    = "ANY"
  integration_uri       = "http://${data.aws_lb.pedido_nlb.dns_name}"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_route" "pedido_route" {
  api_id             = aws_apigatewayv2_api.http_api.id
  route_key          = "ANY /pedidos"
  target             = "integrations/${aws_apigatewayv2_integration.pedido_integration.id}"
  authorizer_id      = aws_apigatewayv2_authorizer.lambda_authorizer.id
  authorization_type = "CUSTOM"
}

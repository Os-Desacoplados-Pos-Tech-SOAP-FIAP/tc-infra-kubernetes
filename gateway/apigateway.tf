resource "aws_apigatewayv2_api" "this" {
  name          = "${var.project_name}-gateway"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true
}

# --- /auth -> Lambda de autenticação por CPF ---

resource "aws_apigatewayv2_integration" "auth_lambda" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = data.terraform_remote_state.lambda.outputs.auth_invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "auth" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "POST /auth"
  target    = "integrations/${aws_apigatewayv2_integration.auth_lambda.id}"
}

resource "aws_lambda_permission" "auth" {
  statement_id  = "AllowApiGatewayAuth"
  action        = "lambda:InvokeFunction"
  function_name = data.terraform_remote_state.lambda.outputs.auth_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}

# --- Authorizer (JWT escopo CLIENTE) ---

resource "aws_apigatewayv2_authorizer" "cliente" {
  api_id                            = aws_apigatewayv2_api.this.id
  authorizer_type                   = "REQUEST"
  authorizer_payload_format_version = "2.0"
  enable_simple_responses           = true
  identity_sources                  = ["$request.header.Authorization"]
  name                              = "cliente-jwt"
  authorizer_uri                    = data.terraform_remote_state.lambda.outputs.authorizer_invoke_arn
  authorizer_result_ttl_in_seconds  = 300
}

resource "aws_lambda_permission" "authorizer" {
  statement_id  = "AllowApiGatewayAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = data.terraform_remote_state.lambda.outputs.authorizer_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/authorizers/${aws_apigatewayv2_authorizer.cliente.id}"
}

# --- Proxy para o ALB (app no EKS) ---
#
# Duas integrações porque o valor de {proxy} é relativo ao prefixo casado pela rota:
# na rota /api/publico/{proxy+} o {proxy} já vem SEM o prefixo, então a URI precisa
# recompor o caminho. A rota catch-all usa ANY /{proxy+} (e não $default, que não
# define variáveis de caminho e por isso é incompatível com URIs contendo {proxy}).

resource "aws_apigatewayv2_integration" "alb_publico" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  integration_uri        = "http://${data.aws_lb.app.dns_name}/api/publico/{proxy}"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_integration" "alb_proxy" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  integration_uri        = "http://${data.aws_lb.app.dns_name}/{proxy}"
  payload_format_version = "1.0"
}

# Rotas do cliente externo: exigem o token da lambda (authorizer).
resource "aws_apigatewayv2_route" "publico" {
  api_id             = aws_apigatewayv2_api.this.id
  route_key          = "ANY /api/publico/{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.alb_publico.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.cliente.id
}

# Demais rotas (funcionários): proxy direto — o app valida o JWT interno.
resource "aws_apigatewayv2_route" "catch_all" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.alb_proxy.id}"
}

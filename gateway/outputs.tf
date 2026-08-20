output "api_endpoint" {
  description = "URL pública do API Gateway (ponto de entrada oficial da aplicação)."
  value       = aws_apigatewayv2_api.this.api_endpoint
}

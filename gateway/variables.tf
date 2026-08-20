variable "aws_region" {
  description = "Região AWS."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefixo dos recursos."
  type        = string
  default     = "oficina-mecanica"
}

variable "ingress_stack_tag" {
  description = "Valor da tag ingress.k8s.aws/stack do ALB criado pelo ingress do app (namespace/nome-do-ingress)."
  type        = string
  default     = "oficina-mecanica/oficina-api"
}

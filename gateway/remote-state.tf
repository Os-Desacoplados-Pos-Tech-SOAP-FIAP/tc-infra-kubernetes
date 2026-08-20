# Stack separada do cluster: o gateway referencia o ALB, que só existe DEPOIS do
# deploy do app (o AWS Load Balancer Controller cria o ALB a partir do Ingress).
# Por isso o apply desta stack é o ÚLTIMO da ordem de subida:
#   cluster -> database -> lambda -> app (CD) -> gateway.
data "terraform_remote_state" "lambda" {
  backend = "s3"
  config = {
    bucket = "tc-fase3-tfstate-538880133939"
    key    = "lambda-auth/terraform.tfstate"
    region = "us-east-1"
  }
}

# ALB criado pelo ingress `oficina-api` (namespace oficina-mecanica).
data "aws_lb" "app" {
  tags = {
    "ingress.k8s.aws/stack" = var.ingress_stack_tag
  }
}

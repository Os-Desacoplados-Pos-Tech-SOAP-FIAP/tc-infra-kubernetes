output "cluster_name" {
  description = "Nome do cluster EKS."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint do API Server do EKS."
  value       = module.eks.cluster_endpoint
}

output "ecr_repository_url" {
  description = "URL do repositório ECR da API (usada pelo CD do app)."
  value       = aws_ecr_repository.api.repository_url
}

output "kubeconfig_command" {
  description = "Comando pronto para configurar o kubeconfig local."
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}"
}

# --- Consumidos por tc-infra-database via terraform_remote_state ---

output "vpc_id" {
  description = "ID da VPC (consumido pelo repo de banco)."
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "IDs das subnets privadas (consumido pelo repo de banco e pela Lambda)."
  value       = module.vpc.private_subnets
}

output "node_security_group_id" {
  description = "SG dos nodes do EKS (consumido pelo repo de banco para liberar o 5432)."
  value       = module.eks.node_security_group_id
}

output "oidc_provider_arn" {
  description = "ARN do OIDC provider do cluster (IRSA — usado por addons como o ALB controller)."
  value       = module.eks.oidc_provider_arn
}

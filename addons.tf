# Addons do cluster via blueprints (IRSA + helm gerenciados pelo módulo).
# O AWS Load Balancer Controller materializa o Ingress `oficina-api` do app em um ALB
# internet-facing — pré-requisito da stack `gateway/` (que referencia esse ALB).
module "addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.16"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  enable_aws_load_balancer_controller = true

  aws_load_balancer_controller = {
    set = [
      # Cluster pequeno (2 nodes): uma réplica basta e sobe mais rápido.
      {
        name  = "replicaCount"
        value = "1"
      },
    ]
  }
}

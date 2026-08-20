# Coleta de telemetria do cluster e da aplicação, encaminhada ao Grafana Cloud.
#
# O chart k8s-monitoring instala o Grafana Alloy em três papéis: métricas do
# cluster (CPU/memória dos pods), logs dos containers e um receiver OTLP que a
# API NestJS usa para enviar traces e métricas de negócio.
#
# Enquanto as credenciais do Grafana Cloud não estiverem cadastradas como secrets
# do repositório, o recurso não é criado (count = 0) — assim o apply da infra
# continua funcionando sem observabilidade.
locals {
  observabilidade_habilitada = var.grafana_cloud_otlp_endpoint != "" && var.grafana_cloud_token != ""
}

resource "helm_release" "k8s_monitoring" {
  count = local.observabilidade_habilitada ? 1 : 0

  name             = "grafana-k8s-monitoring"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "k8s-monitoring"
  version          = "~> 2.0"
  namespace        = "observability"
  create_namespace = true

  values = [yamlencode({
    cluster = { name = var.cluster_name }

    destinations = [{
      name = "grafana-cloud-otlp"
      type = "otlp"
      url  = var.grafana_cloud_otlp_endpoint
      auth = {
        type     = "basic"
        username = var.grafana_cloud_instance_id
        password = var.grafana_cloud_token
      }
      metrics = { enabled = true }
      logs    = { enabled = true }
      traces  = { enabled = true }
    }]

    clusterMetrics = { enabled = true }
    podLogs        = { enabled = true }

    # Receiver OTLP usado pela API (OTEL_EXPORTER_OTLP_ENDPOINT no ConfigMap).
    applicationObservability = {
      enabled = true
      receivers = {
        otlp = {
          http = {
            enabled = true
            port    = 4318
          }
        }
      }
    }

    alloy-metrics  = { enabled = true }
    alloy-logs     = { enabled = true }
    alloy-receiver = { enabled = true }
  })]

  depends_on = [module.eks]
}

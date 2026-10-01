resource "aws_ssm_parameter" "redis_exporter_prometheus_yaml" {
  name  = "redis-exporter-prometheus-yaml"
  type  = "String"
  value = <<-EOT
global:
  scrape_interval: 60s
scrape_configs:
  - job_name: redis_exporter
    static_configs:
      - targets: ['127.0.0.1:9121']
    metric_relabel_configs:
      - source_labels: [__name__, key]
        regex: "^redis_key_size;(laravel-database-queues:invoice|laravel-database-queues:inventory|laravel-database-queues:notification)$"
        action: keep
EOT
}

resource "aws_ssm_parameter" "redis_exporter_cw_agent_config" {
  name = "redis-exporter-cw-agent-config"
  type = "String"
  value = jsonencode({
    agent = {
      metrics_collection_interval = 60
    }
    logs = {
      metrics_collected = {
        prometheus = {
          prometheus_config_path = "/opt/aws/amazon-cloudwatch-agent/etc/custom/prometheus.yaml"
          emf_processor = {
            metric_namespace = "ElastiCache/Prometheus"
            metric_declaration = [
              {
                source_labels    = ["job"]
                label_matcher    = "redis_exporter"
                metric_selectors = ["^redis_key_size$"]
                dimensions = [
                  ["job", "db", "key"]
                ]
              }
            ]
          }
        }
      }
    }
  })
}

variable "lake_bucket_name" {
  description = "Lake bucket name"
}

# Used to create unique lake dataset names
resource "random_string" "random" {
  length           = 6
  special          = false
}

resource "criblio_cribl_lake_dataset" "otel_traces" {
    id        = "otel_demo_otel_traces_${random_string.random.result}"
    lake_id   = "default"
    retention_period_in_days = 7
    bucket_name = var.lake_bucket_name

}

resource "criblio_cribl_lake_dataset" "otel_metrics" {
    id        = "otel_demo_otel_metrics_${random_string.random.result}"
    lake_id   = "default"
    retention_period_in_days = 7
    bucket_name = var.lake_bucket_name

}

resource "criblio_cribl_lake_dataset" "otel_logs" {
    id        = "otel_demo_otel_logs_${random_string.random.result}"
    lake_id   = "default"
    retention_period_in_days = 7
    bucket_name = var.lake_bucket_name

}


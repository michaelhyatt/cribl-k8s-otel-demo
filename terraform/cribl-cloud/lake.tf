# Don't run this file, create the lake datasets manually. 
# The reason is that destroying the datasets will not delete them, only mark them for deletion and they can't be recreated with `terraform apply` until they are fully deleted.
# Manually create the following datasets in Cribl Cloud Lake:
# otel_demo_otel_traces
# otel_demo_otel_metrics
# otel_demo_otel_logs

variable "lake_bucket_name" {
  description = "Lake bucket name"
}

resource "random_string" "random" {
  length           = 6
  special          = false
}

resource "criblio_cribl_lake_dataset" "otel_traces" {
    id        = "otel_demo_otel_traces-${random_string.random.result}"
    lake_id   = "default"
    retention_period_in_days = 7
    bucket_name = var.lake_bucket_name

}

resource "criblio_cribl_lake_dataset" "otel_metrics" {
    id        = "otel_demo_otel_metrics-${random_string.random.result}"
    lake_id   = "default"
    retention_period_in_days = 7
    bucket_name = var.lake_bucket_name

    depends_on = [ criblio_cribl_lake_dataset.otel_traces ]
}

resource "criblio_cribl_lake_dataset" "otel_logs" {
    id        = "otel_demo_otel_logs-${random_string.random.result}"
    lake_id   = "default"
    retention_period_in_days = 7
    bucket_name = var.lake_bucket_name

    depends_on = [ criblio_cribl_lake_dataset.otel_metrics ]
}


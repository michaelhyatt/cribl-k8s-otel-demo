variable "lake_bucket_name" {
  description = "Lake bucket name"
}

variable "create_lakehouse" {
  type    = bool
  description = "Optional creation of a lakehouse connected to the lake datasets. Takes a long time if set to true"
  default = false
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

    depends_on = [ criblio_cribl_lake_dataset.otel_traces ]
}

resource "criblio_cribl_lake_dataset" "otel_logs" {
    id        = "otel_demo_otel_logs_${random_string.random.result}"
    lake_id   = "default"
    retention_period_in_days = 7
    bucket_name = var.lake_bucket_name

    depends_on = [ criblio_cribl_lake_dataset.otel_metrics ]
}

# Add a lakehouse for these lake datasets
resource "criblio_cribl_lake_house" "otel_data_lakehouse" {
    count       = var.create_lakehouse ? 1 : 0
    description = "OTel data lakehouse"
    tier_size   = "small"
    id          = "otel_${random_string.random.result}"
}

resource "criblio_lakehouse_dataset_connection" "otel_data_lakehouse_connection_logs" {
    count                     = var.create_lakehouse ? 1 : 0
    lake_dataset_id = criblio_cribl_lake_dataset.otel_logs.id
    lakehouse_id    = criblio_cribl_lake_house.otel_data_lakehouse[0].id
}

resource "criblio_lakehouse_dataset_connection" "otel_data_lakehouse_connectio_metrics" {
    count           = var.create_lakehouse ? 1 : 0
    lake_dataset_id = criblio_cribl_lake_dataset.otel_metrics.id
    lakehouse_id    = criblio_cribl_lake_house.otel_data_lakehouse[0].id
}

resource "criblio_lakehouse_dataset_connection" "otel_data_lakehouse_connection_traces" {
    count           = var.create_lakehouse ? 1 : 0
    lake_dataset_id = criblio_cribl_lake_dataset.otel_traces.id
    lakehouse_id    = criblio_cribl_lake_house.otel_data_lakehouse[0].id
}
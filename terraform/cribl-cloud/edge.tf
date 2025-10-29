variable "fleet_name" {
  description = "Name of the Edge Fleet"
}

# Create an Edge Fleet group
resource "criblio_group" "k8s_edge_fleet" {
  estimated_ingest_rate = 1024
  id                    = var.fleet_name
  is_fleet              = true
  name                  = var.fleet_name
  product               = "edge"
  provisioned           = true
  worker_remote_access = true
}

locals {
    source_otel_grpc_json                   = jsondecode(file("./config/source_otel_grpc.json"))
    source_otel_http_json                   = jsondecode(file("./config/source_otel_http.json"))
    destination_disk_spool_otel_spool_json  = jsondecode(file("./config/destination_disk_spool_otel_spool.json"))
    destination_cribl_tcp_json              = jsondecode(file("./config/destination_cribl_tcp.json"))
}

# Create disk spool destinations
resource "criblio_destination" "destination_disk_spool_otel_spool" {
  id       = local.destination_disk_spool_otel_spool_json.id
  group_id = criblio_group.k8s_edge_fleet.id

  # Disk Spool configuration from JSON
  output_disk_spool = local.destination_disk_spool_otel_spool_json
}

# Create Cribl TCP destination
resource "criblio_destination" "destination_cribl_tcp" {
    id       = local.destination_cribl_tcp_json.id
    group_id = criblio_group.k8s_edge_fleet.id

    # Cribl TCP configuration from JSON
    output_cribl_tcp = local.destination_cribl_tcp_json
}

# Create GRPC OTel source
resource "criblio_source" "source_otel_grpc" {
  id       = local.source_otel_grpc_json.id
  group_id = criblio_group.k8s_edge_fleet.id

  # OpenTelemetry configuration from JSON
  input_open_telemetry = local.source_otel_grpc_json

  depends_on = [ criblio_destination.destination_cribl_tcp, criblio_destination.destination_disk_spool_otel_spool ]
}

# Create HTTP OTel source
resource "criblio_source" "source_otel_http" {
  id       = local.source_otel_http_json.id
  group_id = criblio_group.k8s_edge_fleet.id

  # OpenTelemetry configuration from JSON
  input_open_telemetry = local.source_otel_http_json

  depends_on = [ criblio_destination.destination_cribl_tcp, criblio_destination.destination_disk_spool_otel_spool ]
}
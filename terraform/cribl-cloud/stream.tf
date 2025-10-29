variable "worker_group_name" {
  description = "Name of the Stream Worker Group"
  default = "otel-demo-k8s-wg"
}

# Create a Stream Worker Group
resource "criblio_group" "k8s_stream_worker_group" {
  id                    = var.worker_group_name
  is_fleet              = false
  name                  = var.worker_group_name
  product               = "stream"
  provisioned           = true
  on_prem               = true
  worker_remote_access = true
}

# Create Cribl Lake dataset for OTel traces
resource "criblio_destination" "otel_traces_lake_dataset" {
    id       = "otel-traces"
    group_id = criblio_group.k8s_stream_worker_group.id

    output_cribl_lake = {
        id          = "otel-traces"
        type        = "cribl_lake"
        dest_path   = "otel_demo_otel_traces"
    }
  
}

# Create Cribl Lake dataset for OTel metrics
resource "criblio_destination" "otel_metrics_lake_dataset" {
    id       = "otel-metrics"
    group_id = criblio_group.k8s_stream_worker_group.id  

    output_cribl_lake = {
        id          = "otel-metrics"
        type        = "cribl_lake"
        dest_path   = "otel_demo_otel_metrics"
    }
}

# Create Cribl Lake dataset for OTel logs
resource "criblio_destination" "otel_logs_lake_dataset" {
    id       = "otel-logs"
    group_id = criblio_group.k8s_stream_worker_group.id

    output_cribl_lake = {
        id          = "otel-logs"
        type        = "cribl_lake"
        dest_path   = "otel_demo_otel_logs"
    }
}

# Create a Router destination to route OTel data to appropriate Lake datasets
resource "criblio_destination" "otel_data_router" {
    id       = "otel-data-router"
    group_id = criblio_group.k8s_stream_worker_group.id

    output_router = {
      id =      "otel-data-router"
      type =    "router"
      rules = [ 
        {
            filter = "__otlp.type == 'traces'"
            output = "otel-traces"
            description = "OTel traces to Lake"
            final = true
        },
        {
            filter = "__otlp.type == 'metrics'"
            output = "otel-metrics"
            description = "OTel metrics to Lake"
            final = true
        },
        {
            filter = "__otlp.type == 'logs'"
            output = "otel-logs"
            description = "OTel logs to Lake"
            final = true
        }
      ]
    }
}

# Create Prometheus destination
resource "criblio_destination" "elastic-prometheus" {
    id          = "elastic-prometheus"
    group_id    = criblio_group.k8s_stream_worker_group.id

    output_prometheus = {
      id        = "elastic-prometheus"
      type      = "prometheus"
      url       = "http://prometheus.elastic.svc.cluster.local:9201"
      auth_type = "none"
    }
}

# Create OTel destination
resource "criblio_destination" "elastic-otel" {
    id          = "elastic-otel"
    group_id    = criblio_group.k8s_stream_worker_group.id

    output_open_telemetry = {
      id                = "elastic-otel"
      type              = "open_telemetry"
      protocol          = "grpc"
      version           = "1.3.1"
      otlp_version      = "1.3.1"
      auth_type         = "none" 
      endpoint          = "apm.elastic.svc.cluster.local:8200"
      tls = {
        disabled = true
      }
    }
}
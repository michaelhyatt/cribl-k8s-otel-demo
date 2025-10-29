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
  provisioned           = false
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

    depends_on = [ criblio_destination.otel_logs_lake_dataset, criblio_destination.otel_metrics_lake_dataset, criblio_destination.otel_traces_lake_dataset ]
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

# Create a Cribl HTTP source routed to Elastic OTel
resource "criblio_source" "in_k8s_cribl_http" {
    id       = "in_k8s_cribl_http"
    group_id = criblio_group.k8s_stream_worker_group.id

        input_cribl_http = {
        id              = "in_k8s_cribl_http"
        type            = "cribl_http"
        port            = 10200
        send_to_routes  = false
        tls             = {
            disabled = true
        }
        connections = [ 
            {
                output = "elastic-otel"
            }
        ]
        disabled        = false
    }

    depends_on = [ criblio_destination.elastic-otel ]

    lifecycle {
      create_before_destroy = true
    }

}

# Create a Cribl TCP source sending data to routes
resource "criblio_source" "in_k8s_cribl_tcp" {
    id       = "in_k8s_cribl_tcp"
    group_id = criblio_group.k8s_stream_worker_group.id

    input_cribl_tcp = {
        id              = "in_k8s_cribl_tcp"
        type            = "cribl_tcp"
        port            = 10300
        send_to_routes  = true
        disabled        = false
    }
}

# Install cribl-opentelemetry pack
resource "criblio_pack" "cribl_opentelemetry_pack" {
    id            = "cribl-opentelemetry-pack"
    group_id      = criblio_group.k8s_stream_worker_group.id
    description   = "Cribl OpenTelemetry Pack"
    source        = "https://packs.cribl.io/dl/cribl-opentelemetry/0.1.0/cribl-opentelemetry-0.1.0.crbl"
    display_name  = "cribl-opentelemetry-pack" 
    version       = "0.1.0"
}

output "pack_details" {
  value = criblio_pack.cribl_opentelemetry_pack
}


# Commit and deploy the configuration
data "criblio_config_version" "stream_configversion" {
  id         = criblio_group.k8s_stream_worker_group.id
  depends_on = [ criblio_commit.stream_commit ]
}

resource "criblio_commit" "stream_commit" {
  effective = true
  group     = criblio_group.k8s_stream_worker_group.id
  message   = "Automated Stream configuration commit"

  depends_on = [ criblio_source.in_k8s_cribl_http, criblio_source.in_k8s_cribl_tcp ]
}

resource "criblio_deploy" "stream_deploy" {
  id      = criblio_group.k8s_stream_worker_group.id
  version = data.criblio_config_version.stream_configversion.items[0]

  depends_on = [ criblio_commit.stream_commit ]
}
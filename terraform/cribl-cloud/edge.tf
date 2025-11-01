variable "fleet_name" {
  description = "Name of the Edge Fleet"
  default = "otel-demo-k8s-fleet"
}

# Create an Edge Fleet group
resource "criblio_group" "k8s_edge_fleet" {
  id                    = var.fleet_name
  is_fleet              = true
  name                  = var.fleet_name
  product               = "edge"
  provisioned           = true
  worker_remote_access = true
}

# Create disk spool destinations
resource "criblio_destination" "destination_disk_spool_otel_spool" {
  id       = "otel-spool"
  group_id = criblio_group.k8s_edge_fleet.id

  output_disk_spool = {
        id = "otel-spool"
        type = "disk_spool"
  }
}

resource "criblio_destination" "k8s_events" {
  id       = "k8s-events-spool"
  group_id = criblio_group.k8s_edge_fleet.id

  output_disk_spool = {
        id = "k8s-events-spool"
        type = "disk_spool"
  }
}

resource "criblio_destination" "k8s_logs" {
  id       = "k8s-logs-spool"
  group_id = criblio_group.k8s_edge_fleet.id

  output_disk_spool = {
        id = "k8s-logs-spool"
        type = "disk_spool"
  }
}

resource "criblio_destination" "k8s_metrics" {
  id       = "k8s-metrics-spool"
  group_id = criblio_group.k8s_edge_fleet.id

  output_disk_spool = {
        id = "k8s-metrics-spool"
        type = "disk_spool"
  }
}

# Create Cribl TCP destination
resource "criblio_destination" "destination_cribl_tcp" {
    id       = "cribl-tcp"
    group_id = criblio_group.k8s_edge_fleet.id

    output_cribl_tcp = {
        id = "cribl-tcp"
        type = "cribl_tcp"
        host = "cribl-worker-logstream-workergroup"
        port = 10300
        load_balanced = false
        hosts = [
            {
                host = "cribl-worker-logstream-workergroup"
                port = 10300
            }
        ]
    }
}

# Update in_kube_* sources connecting it to the disk spools
resource "criblio_source" "in_kube_events" {
    id      = "in_kube_events-${random_string.random.result}"
    group_id = criblio_group.k8s_edge_fleet.id

    input_kube_events = {
        id      = "in_kube_events-${random_string.random.result}"
        type    = "kube_events"
        send_to_routes = false
        connections = [ {
            output = criblio_destination.k8s_events.id
        } ]
    }

    lifecycle {
        create_before_destroy = true
    }
}

resource "criblio_source" "in_kube_logs" {
    id      = "in_kube_logs-${random_string.random.result}"
    group_id = criblio_group.k8s_edge_fleet.id

    input_kube_logs = {
        id      = "in_kube_logs-${random_string.random.result}"
        type    = "kube_logs"
        send_to_routes = false
        connections = [ {
            output = criblio_destination.k8s_logs.id
        } ]
    }

    lifecycle {
        create_before_destroy = true
    }
}

resource "criblio_source" "in_kube_metrics" {
    id      = "in_kube_metrics-${random_string.random.result}"
    group_id = criblio_group.k8s_edge_fleet.id

    input_kube_metrics = {
        id      = "in_kube_metrics-${random_string.random.result}"
        type    = "kube_metrics"
        send_to_routes = false
        connections = [ {
            output = criblio_destination.k8s_metrics.id
        } ]
    }

    lifecycle {
        create_before_destroy = true
    }
}

# Create GRPC OTel source
resource "criblio_source" "source_otel_grpc" {
  id       = "otel-grpc"
  group_id = criblio_group.k8s_edge_fleet.id

  input_open_telemetry = {
    id              = "otel-grpc"
    type            = "open_telemetry"
    protocol        = "grpc"
    otlp_version    = "1.3.1"
    version         = "1.3.1"
    extract_logs    = true
    extract_metrics = true
    extract_spans   = true
    send_to_routes  = false
    connections = [ 
        {
            output = "cribl-tcp"
        },
        {
            output = "otel-spool"
        }
    ]
  }

  depends_on = [ criblio_destination.destination_cribl_tcp, criblio_destination.destination_disk_spool_otel_spool ]

  lifecycle {
    create_before_destroy = true
  }
}

# Create HTTP OTel source
resource "criblio_source" "source_otel_http" {
  id       = "otel-http"
  group_id = criblio_group.k8s_edge_fleet.id

    input_open_telemetry = {
    id              = "otel-http"
    type            = "open_telemetry"        
    protocol        = "http"
    otlp_version    = "1.3.1"
    version         = "1.3.1"
    port            = 4318
    extract_logs    = true
    extract_metrics = true
    extract_spans   = true
    send_to_routes  = false
    connections = [ 
        {
            output = "cribl-tcp"
        },
        {
            output = "otel-spool"
        }
    ]
  }

  depends_on = [ criblio_destination.destination_cribl_tcp, criblio_destination.destination_disk_spool_otel_spool ]
  
  lifecycle {
    create_before_destroy = true
  }
}


# Commit and deploy the configuration
data "criblio_config_version" "edge_configversion" {
  id         = criblio_group.k8s_edge_fleet.id
  depends_on = [criblio_commit.edge_commit]
}

resource "criblio_commit" "edge_commit" {
  effective = true
  group     = criblio_group.k8s_edge_fleet.id
  message   = "Automated Edge configuration commit"

  depends_on = [ criblio_source.source_otel_grpc, criblio_source.source_otel_http ]
}

resource "criblio_deploy" "edge_deploy" {
  id      = criblio_group.k8s_edge_fleet.id
  version = data.criblio_config_version.edge_configversion.items[0]

  depends_on = [ criblio_commit.edge_commit ]
}

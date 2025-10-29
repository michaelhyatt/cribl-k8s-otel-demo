terraform {
  required_providers {
    criblio = {
      source  = "criblio/criblio"
    }
  }
}

provider "criblio" {
  # Credentials will be read from environment variables
}

variable "fleet_name" {
  description = "Name of the Edge Fleet"
}

variable "stream_worker_group" {
  description = "Name of the Stream Worker Group"
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


# Create Stream Worker group
resource "criblio_group" "k8s_stream_worker_group" {
  estimated_ingest_rate = 1024
  id                    = var.stream_worker_group
  is_fleet              = false
  name                  = var.stream_worker_group
  product               = "stream"
  provisioned           = true
  worker_remote_access = true
}

output "k8s_edge_fleet" {
  value = criblio_group.k8s_edge_fleet
}

output "k8s_stream_worker_group" {
  value = criblio_group.k8s_stream_worker_group
}
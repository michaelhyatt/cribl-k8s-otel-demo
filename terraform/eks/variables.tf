# Update it to the correct region
variable "region" {
  description = "AWS region to deploy the cluster in"
  default = "us-west-2"
}

variable "demo_name_prefix" {
  description = "Give it a name we can recognise in AWS EC2 console"
}

variable "cribl_edge_leader_url" {
  description = "The leader URL for the Cribl Edge"
}

variable "cribl_edge_token" {
  description = "The token for the Cribl Edge"
}

variable "cribl_edge_version" {
  description = "The version of the Cribl Edge"
}

variable "cribl_edge_fleet" {
  description = "The fleet name for the Cribl Edge"
}

variable "cribl_stream_leader_url" {
  description = "The leader URL for the Cribl Stream"
}

variable "cribl_stream_token" {
  description = "The token for the Cribl Stream"
}

variable "cribl_stream_version" {
  description = "The version of the Cribl Stream"
}

variable "cribl_stream_worker_group" {
  description = "The worker group for the Cribl Stream"
}
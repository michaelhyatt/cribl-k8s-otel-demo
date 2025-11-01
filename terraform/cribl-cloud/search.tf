resource "criblio_pack" "search_pack" {
    id              = "cribl-k8s-otel-demo"
    group_id        = "default_search"
    display_name    = "OTel demo Search pack"
    filename        = "${abspath(path.module)}/cribl-k8s-otel-demo_0-0-3.crbl"
    version         = "0.0.3"
    description     = "OTel demo Search pack with dashboards"

    depends_on = [ criblio_search_dataset.k8s_disk_spool ]
}

# Create the k8s_disk_spool dataset
# Destroy doesn't delete it
resource "criblio_search_dataset" "k8s_disk_spool" {
    edge_dataset = {
        id = "k8s_disk_spool"
        type = "cribl_edge"
        path = "$CRIBL_SPOOL_DIR/out/disk_spool/$${output_id}/$${__earliest:%s}_$${__latest:%s}/"
        filter = "!source.endsWith('.tmp')"
        fleets = [ var.fleet_name ]
        provider_id = "cribl_edge"
        description = "Edge dataset k8s_disk_spool"
    }

    lifecycle {
      create_before_destroy = true
    }
}
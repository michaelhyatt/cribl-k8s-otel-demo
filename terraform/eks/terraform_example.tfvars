# AWS Region
region              = "ap-southeast-2"

# Give the created resources a prefix to be able to identify them in AWS console
demo_name_prefix    = "mhyatt-otel-demo"

# Cribl.Cloud details

# Stream
cribl_stream_version        =   "4.10.0"
cribl_stream_worker_group   =   "otel-demo-k8s-wg"
cribl_stream_token          =   <token>
cribl_stream_leader_url     =   <leader-url>

# Edge
cribl_edge_version          =   "4.10.0"
cribl_edge_fleet            =   "otel-demo-k8s-fleet"
cribl_edge_token            =   <token>
cribl_edge_leader_url       =   <leader-url>

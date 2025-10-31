region              = "us-west-2"

# Ubuntu 24 Server AMI, if you are changing the region, you may need to change the AMI
ami                 = "ami-0cf2b4e024cdb6960"

# Give the instance a name so we can easily identify it in EC2 console
server_name         = "mhyatt-otel-demo"

# AWS Key Pair: pem file and key name registered in AWS
pemfile             = "/Users/user/Downloads/mhyatt-keypair-2.pem"
keyname             = "mhyatt-keypair-2"

# Cribl.Cloud details

# Stream
cribl_stream_version        =   "4.14.1"
cribl_stream_worker_group   =   "otel-demo-k8s-wg"
cribl_stream_token          =   <token>
cribl_stream_leader_url     =   <leader-url>

# Edge
cribl_edge_version          =   "4.14.1"
cribl_edge_fleet            =   "otel-demo-k8s-fleet"
cribl_edge_token            =   <token>
cribl_edge_leader_url       =   <leader-url>

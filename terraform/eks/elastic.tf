# Install Elastic cluster using ECK
resource "null_resource" "elastic_definitions" {
  depends_on = [ null_resource.wait_for_cluster ]

  provisioner "local-exec" {
    command = <<EOT
        kubectl create -f https://download.elastic.co/downloads/eck/2.16.0/crds.yaml
        kubectl apply -f https://download.elastic.co/downloads/eck/2.16.0/operator.yaml
    EOT
  }
}

resource "null_resource" "wait_for_elastic_operator" {
  depends_on = [ null_resource.elastic_definitions ]

  provisioner "local-exec" {
    command = <<EOF
      while ! kubectl wait --for=condition=Ready pod --selector=control-plane=elastic-operator -n elastic-system --timeout=300s &> /dev/null; do
        echo "Waiting for Elastic Operator to be ready"
        echo ""
        sleep 30
      done
    EOF
  }
  
}

resource "null_resource" "provision_elastic_stack" {
    depends_on = [ null_resource.wait_for_elastic_operator ]
    
    provisioner "local-exec" {
        command = <<EOF
            kubectl apply -n elastic-system -f ${path.module}/../../elastic/license.yaml 
            kubectl create ns elastic
            kubectl apply -n elastic -f ${path.module}/../../elastic/elastic.yaml
        EOF
    }
}

resource "null_resource" "add_dashboard" {
    depends_on = [ null_resource.wait_for_kibana_hostname ]
    
    provisioner "local-exec" {
        command = <<EOF
            kubectl apply -n elastic -f ${path.module}/../../elastic/add_dashboard.yml
        EOF
    }
}
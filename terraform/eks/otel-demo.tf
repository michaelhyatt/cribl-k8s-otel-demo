# Install otel-demo app
resource "null_resource" "provision_otel_demo_app" {
    depends_on = [ null_resource.wait_for_cluster ]
    
    provisioner "local-exec" {
        command = <<EOF
            kubectl apply -n otel-demo -f ${path.module}/../../otel-demo/opentelemetry-demo.yaml
        EOF
    }
}
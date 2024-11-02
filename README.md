# Kubernetes and application observability demo with Cribl
## Prerequisites
* K8s cluster
* `kubectl`
* Helm
## Setup
### Deploy Cribl components
Add Cribl Helm repo chart:
```
helm repo add cribl https://criblio.github.io/helm-charts/
```
#### Deploy Cribl Edge as DaemonSet
```
helm install --repo "https://criblio.github.io/helm-charts/" --version "^4.9.1" --create-namespace -n "cribl" \
--set "cribl.leader=tls://<token>@<leader-url>?group=<fleet>" \
--set "env.CRIBL_K8S_TLS_REJECT_UNAUTHORIZED=0" \
--values cribl/edge/values.yaml \
"cribl-edge" edge
```
### Deploy otel-demo app
#### Deploy using `kubectl`:
```
kubectl apply --namespace otel-demo -f https://raw.githubusercontent.com/open-telemetry/opentelemetry-demo/main/kubernetes/opentelemetry-demo.yaml
```
#### Deploy using Helm chart
Install the chart, only once:
```
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
```
Deploy the app with the custom `values.yaml` file:
```
helm install my-otel-demo open-telemetry/opentelemetry-demo --values ./otel-demo/my-values-file.yaml
```
#### Forward the port locally, if using local k8s cluster, such as minikube:
```
kubectl port-forward svc/my-otel-demo-frontendproxy 8080:8080
```
### Deploy Elastic cluster
### Cribl Edge configuration
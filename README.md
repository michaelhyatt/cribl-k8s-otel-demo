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
helm install --repo "https://criblio.github.io/helm-charts/" --version "^4.9.0" --create-namespace -n "cribl" \
--set "cribl.leader=tls://<token>@<leader-url>?group=<fleet>" \
--set "env.CRIBL_K8S_TLS_REJECT_UNAUTHORIZED=0" \
--values cribl/edge/values.yaml \
"cribl-edge" edge
```
#### Configure Cribl Edge
OTel receivers
Routing to Stream
Sending data to local Elastic cluster
#### Deploy Cribl Stream worker
```
helm install --repo "https://criblio.github.io/helm-charts/" --version "^4.9.0" --create-namespace -n "cribl" \
--set "config.host=<leader-url>" \
--set "config.token=<token>" \
--set "config.group=<worker-group-name>" \
--set "config.tlsLeader.enable=true"  \
--set "env.CRIBL_K8S_TLS_REJECT_UNAUTHORIZED=0" \
--values cribl/stream/values.yaml \
"cribl-worker" logstream-workergroup
```
### Deploy otel-demo app
#### Deploy using `kubectl`:
```
kubectl apply --namespace otel-demo -f otel-demo/opentelemetry-demo.yaml
```
#### Forward the port locally, if using local k8s cluster, such as minikube:
```
kubectl port-forward svc/my-otel-demo-frontendproxy 8080:8080
```
### Deploy Elastic cluster
## Misc actions
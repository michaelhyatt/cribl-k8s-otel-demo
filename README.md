# Kubernetes and application observability demo with Cribl

## Prerequisites
### K8s cluster
    *  `kind create cluster --config kind/kind-cluster-config.yaml --name cluster`
    * `kubectl cluster-info --context kind-cluster`
### `kubectl`

### Helm

### Ngrok
Reverse tunneling into local k8s cluster

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
Routing to Stream Cribl TCP
Sending OTel data to local Elastic cluster
Sending Prometheus metrics to local Elastic cluster
Sending logs to local Elastic cluster

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

#### Configure Cribl Stream
Receive Cribl TCP traffic
Forward it to Lake
Receive Cribl HTTP traffic for replays

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
#### Install ECK operator
```
kubectl create -f https://download.elastic.co/downloads/eck/2.14.0/crds.yaml
kubectl apply -f https://download.elastic.co/downloads/eck/2.14.0/operator.yaml
```

#### Monitor the operator logs
```
kubectl -n elastic-system logs -f statefulset.apps/elastic-operator
```

#### Create `elastic` namespace and deploy Elastic stack
```
kubectl create ns elastic
kubectl apply -n elastic -f elastic/elastic.yaml
```

#### Retrieve the password for `elastic` user
```
kubectl get secret -n elastic es-es-elastic-user -o go-template='{{.data.elastic | base64decode}}'
```

#### Retrieve the token to connect to the APM server
```
kubectl get secret -n elastic apm-apm-token -o go-template='{{index .data "secret-token" | base64decode}}'
```

### Deploy ngrok agent

## Misc actions
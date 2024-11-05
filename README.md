# Kubernetes and application observability demo with Cribl

## Prerequisites
### `kubectl`
```
brew install kubectl
```

### K8s cluster
I used docker-desktop inbuilt k8s cluster, will work with `minikube` as well, or you can use `kind` if you want to simulate a multi-node cluster locally.
#### kind
https://kind.sigs.k8s.io/
Install:
```
brew install kind
```
Create cluster:
```
kind create cluster --config kind/kind-cluster-config.yaml --name cluster`
kubectl cluster-info --context kind-cluster
```

### Helm
```
brew install helm
```

### Ngrok
TODO: Reverse tunneling into local k8s cluster

## Setup
### Deploy Cribl components
1. Add Cribl Helm repo chart:
```
helm repo add cribl https://criblio.github.io/helm-charts/
```
2. Create a worker group `otel-demo-k8s-wg`

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
* Receive Cribl TCP traffic
    * hostname 0.0.0.0 port 10300

#### Deploy Cribl Edge as DaemonSet
```
helm install --repo "https://criblio.github.io/helm-charts/" --version "^4.9.0" --create-namespace -n "cribl" \
--set "cribl.leader=tls://<token>@<leader-url>?group=<fleet>" \
--set "env.CRIBL_K8S_TLS_REJECT_UNAUTHORIZED=0" \
--values cribl/edge/values.yaml \
"cribl-edge" edge
```

#### Configure Cribl Edge
* Create fleet otel-demo-k8s-fleet
* Create 2 OTel sources, grpc and http, version 1.3.1:
    * hostname: 0.0.0.0, grpc on port 4317, http on port 4318

* Route both to Stream Cribl TCP destination
    * Address `cribl-worker-logstream-workergroup`, port 10300 

TODO:
* Sending OTel data to local Elastic cluster
* Sending Prometheus metrics to local Elastic cluster
* Sending logs to local Elastic cluster

TODO:
* Forward it to Lake
* Receive Cribl HTTP traffic for replays

### Deploy otel-demo app
#### Deploy using `kubectl`:
```
kubectl apply --namespace otel-demo -f otel-demo/opentelemetry-demo.yaml
```

#### Forward the 8080 port 
To access the app and the loadgen
```
kubectl port-forward svc/my-otel-demo-frontendproxy 8080:8080
```
App: http://localhost:8080/

Loadgen: http://localhost:8080/loadgen/

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
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
helm install --repo "https://criblio.github.io/helm-charts/" --version "^4.9.1" --create-namespace -n "cribl" \
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
helm install --repo "https://criblio.github.io/helm-charts/" --version "^4.9.1" --create-namespace -n "cribl" \
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

* Sending OTel data to local Elastic cluster
    * Create an OTel destination, address `http://apm.elastic.svc.cluster.local:8200`, OTel version 1.3.1, TLS off

* Sending Prometheus metrics to local Elastic cluster
    * Create a Prometheus destination, address `http://prometheus.elastic.svc.cluster.local:9201`, authentication None, CErtificate validation off

TODO:
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

#### Forward the 5601 port to access Kibana
```
kubectl port-forward svc/my-otel-demo-frontendproxy 5601:5601
```
Kibana: http://localhost:5601

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

### Deploy ngrok agent

Using helm, add the ngrok repo:
```
helm repo add ngrok https://charts.ngrok.com
```

Set your environment variables with your ngrok credentials. Replace [AUTHTOKEN] and [API_KEY] with your Authtoken and API key from above.
```
export NGROK_AUTHTOKEN=[AUTHTOKEN]
export NGROK_API_KEY=[API_KEY]
```

Install the ngrok Kubernetes Operator in your cluster, replacing [AUTHTOKEN] and [API_KEY] with your Authtoken and API key from above:

```
helm install ngrok-ingress-controller ngrok/kubernetes-ingress-controller \
  --namespace ngrok-ingress-controller \
  --create-namespace \
  --set credentials.apiKey=$NGROK_API_KEY \
  --set credentials.authtoken=$NGROK_AUTHTOKEN
```

Apply the manifest file to your k8s cluster.
```
kubectl apply -f ngrok/ngrok-manifest.yaml
```
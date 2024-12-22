# Kubernetes and application observability demo with Cribl

## [Prerequisites](./PREREQUISITES.md)
`kubectl`, `kind`, `helm`

## Setup
* [Deploy Cribl Stream components](./cribl/stream/STREAM_SETUP.md)
* [Deploy Cribl Edge components](./cribl/edge/EDGE_SETUP.md)

## Diagram
![diagram](images/k8s-o11y-demo.png)

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
kubectl create -f https://download.elastic.co/downloads/eck/2.15.0/crds.yaml
kubectl apply -f https://download.elastic.co/downloads/eck/2.15.0/operator.yaml
```

#### Monitor the operator logs
```
kubectl -n elastic-system logs -f statefulset.apps/elastic-operator
```

#### Optional: enable enterprise trial license
Can activate the trial of some of the premium features, such as anomaly detection and service map.
```
kubectl apply -n elastic-system -f elastic/license.yaml 
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

Set your environment variables with your ngrok credentials. Replace [AUTHTOKEN] and [API_KEY] with your Authtoken and API key.
```
export NGROK_AUTHTOKEN=[AUTHTOKEN]
export NGROK_API_KEY=[API_KEY]
```

Install the ngrok Kubernetes Operator in your cluster, replacing [AUTHTOKEN] and [API_KEY] with your Authtoken and API key:

```
helm install ngrok-ingress-controller ngrok/kubernetes-ingress-controller \
  --namespace ngrok-ingress-controller \
  --create-namespace \
  --set credentials.apiKey=$NGROK_API_KEY \
  --set credentials.authtoken=$NGROK_AUTHTOKEN
```

Create a domain in ngrok and update its name in `ngrok/ngrok-manifest.yaml`

Apply the manifest file to your k8s cluster.
```
kubectl apply -f ngrok/ngrok-manifest.yaml
```
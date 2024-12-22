# Kubernetes and application observability demo with Cribl

## [Prerequisites](./PREREQUISITES.md)
`kubectl`, `kind`, `helm`

## Setup
### [Deploy Cribl Stream components](./cribl/stream/STREAM_SETUP.md)

## Diagram
![diagram](images/k8s-o11y-demo.png)

## Configure Cribl Edge
### Create fleet otel-demo-k8s-fleet
### Create 2 OTel sources, grpc and http, version 1.3.1:
<details>
<summary>GRPC OTel source JSON</summary>

    ```json
    {
        "id": "otel-grpc",
        "disabled": false,
        "sendToRoutes": false,
        "pqEnabled": false,
        "streamtags": [],
        "host": "0.0.0.0",
        "port": 4317,
        "tls": {
            "disabled": true
        },
        "protocol": "grpc",
        "extractSpans": true,
        "extractMetrics": true,
        "otlpVersion": "1.3.1",
        "authType": "none",
        "maxActiveCxn": 1000,
        "extractLogs": true,
        "type": "open_telemetry",
        "connections": []
    }
    ```
</details>
<details>
<summary>HTTP OTel source JSON</summary>

    ```json
    {
    "id": "otel-http",
    "disabled": false,
    "sendToRoutes": false,
    "pqEnabled": false,
    "streamtags": [],
    "host": "0.0.0.0",
    "port": 4318,
    "tls": {
        "disabled": true
    },
    "maxActiveReq": 256,
    "maxRequestsPerSocket": 0,
    "requestTimeout": 0,
    "socketTimeout": 0,
    "keepAliveTimeout": 15,
    "enableHealthCheck": false,
    "ipAllowlistRegex": "/.*/",
    "ipDenylistRegex": "/^$/",
    "protocol": "http",
    "extractSpans": true,
    "extractMetrics": true,
    "otlpVersion": "1.3.1",
    "authType": "none",
    "extractLogs": true,
    "maxActiveCxn": 1000,
    "type": "open_telemetry",
    "connections": []
    }
    ```
</details>

* Route both to Stream Cribl TCP destination at address `cribl-worker-logstream-workergroup`, port 10300 


* Sending OTel data to local Elastic cluster
    * Create an OTel destination, address `http://apm.elastic.svc.cluster.local:8200`, OTel version 1.3.1, TLS off

* Optional: Sending Prometheus metrics to local Elastic cluster
    * Create a Prometheus destination, address `http://prometheus.elastic.svc.cluster.local:9201`, authentication None, Certificate validation off

TODO:
* Sending logs to local Elastic cluster

TODO:
* Forward it to Lake
* Receive Cribl HTTP traffic for replays and forwward it to Elastic OTel

#### Deploy Cribl Edge as DaemonSet
```
helm install --repo "https://criblio.github.io/helm-charts/" --version "^4.9.3" --create-namespace -n "cribl" \
--set "cribl.leader=tls://<token>@<leader-url>?group=otel-demo-k8s-fleet" \
--set "env.CRIBL_K8S_TLS_REJECT_UNAUTHORIZED=0" \
--values cribl/edge/values.yaml \
"cribl-edge" edge
```

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
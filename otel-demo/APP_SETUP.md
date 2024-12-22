# Demo app setup

## Deploy `otel-demo` app
```
kubectl apply --namespace otel-demo -f otel-demo/opentelemetry-demo.yaml
```
The app may take some time to download all the pods and start. Good point to go to `k9s` to wait for all the pods of `otel-demo` are up. Or, simply use `kubectl`:
```
kubectl get pods -n otel-demo -w
```
Once the app is running, the Edge OTel sources and Stream TCP source should start showing traffic. Also, `RED Metrics` dashboard in Kibana begins to show data.

## Access the otel-demo app and loadgen UI
To access the app and the loadgen, forward port 8080
```
kubectl port-forward -n otel-demo svc/opentelemetry-demo-frontendproxy 8080:8080
```
* App: http://localhost:8080/
* Loadgen: http://localhost:8080/loadgen/

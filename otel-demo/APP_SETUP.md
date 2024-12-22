# Demo app setup

## Deploy `otel-demo` app
```
kubectl apply --namespace otel-demo -f otel-demo/opentelemetry-demo.yaml
```

## Access the otel-demo app and loadgen UI
To access the app and the loadgen, forward port 8080
```
kubectl port-forward svc/my-otel-demo-frontendproxy 8080:8080
```
* App: http://localhost:8080/
* Loadgen: http://localhost:8080/loadgen/

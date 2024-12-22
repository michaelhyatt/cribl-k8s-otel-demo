# Elastic stack setup using ECK (Elastic Cloud on Kubernetes)

## Install ECK operator
```
kubectl create -f https://download.elastic.co/downloads/eck/2.15.0/crds.yaml
kubectl apply -f https://download.elastic.co/downloads/eck/2.15.0/operator.yaml
```

## Check the operator is up by seeing the operator logs appear
```
kubectl -n elastic-system logs -f statefulset.apps/elastic-operator
```

## Optional: enable enterprise trial license
Can activate the trial of some of the premium features, such as anomaly detection and service map.
```
kubectl apply -n elastic-system -f elastic/license.yaml 
```

## Create `elastic` namespace and deploy Elastic stack
```
kubectl create ns elastic
kubectl apply -n elastic -f elastic/elastic.yaml
```

#### Forward the 5601 port to access Kibana
```
kubectl port-forward svc/my-otel-demo-frontendproxy 5601:5601
```
* Kibana: http://localhost:5601
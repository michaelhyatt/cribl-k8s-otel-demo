# Elastic stack setup using ECK (Elastic Cloud on Kubernetes)

## Install ECK operator
```
kubectl create -f https://download.elastic.co/downloads/eck/2.16.0/crds.yaml
kubectl apply -f https://download.elastic.co/downloads/eck/2.16.0/operator.yaml
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

## Load `RED Metrics` dashboard
Wait for the main Elastic stack to come up. It is a good point to check if the OTel and Prometheus Stream destinations are up when Elastic Agent is up.
```
kubectl apply -n elastic -f elastic/add_dashboard.yml
```

## Forward the 5601 port to access Kibana
```
kubectl port-forward svc/kibana-kb-http -n elastic 5601:5601 --address 0.0.0.0
```
* Kibana: http://localhost:5601

## Stopping Port Forwarding
If kubectl port-forward is running in your terminal, press Ctrl + C to terminate the command and immediately stop forwarding ports.​

If you ran the process in the background or closed the original terminal, find and kill the process:

### List kubectl processes:
```bash
ps aux | grep kubectl
```
Identify the correct process for your port-forward and note the PID.

### Kill the process:
```bash
kill <PID>
```

### Or kill all kubectl processes with:
```bash
pkill kubectl
```
(Be cautious with this, as it will stop all kubectl operations, not just port-forwarding).
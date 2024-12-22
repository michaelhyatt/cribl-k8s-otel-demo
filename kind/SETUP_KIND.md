# Create cluster
```
kind create cluster --config kind/kind-cluster-config.yaml --name cluster
kubectl cluster-info --context kind-cluster
```
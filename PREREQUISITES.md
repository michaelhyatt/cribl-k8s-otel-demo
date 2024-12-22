# Prerequisites
## `kubectl`
```
brew install kubectl
```

## K8s cluster
I used docker-desktop inbuilt k8s cluster, will work with `minikube` as well, or you can use `kind` if you want to simulate a multi-node cluster locally.
## kind
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

## Helm
```
brew install helm
```

## Add Cribl Helm repo chart:
```
helm repo add cribl https://criblio.github.io/helm-charts/
```
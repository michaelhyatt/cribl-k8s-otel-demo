## Install Chaos Mesh using Helm:

### Add Chaos Mesh Helm repo:

```bash
helm repo add chaos-mesh https://charts.chaos-mesh.org
helm repo update
```

### Create a namespace:

```bash
kubectl create ns chaos-mesh
```

### Install Chaos Mesh with dashboard:

```bash
helm install chaos-mesh chaos-mesh/chaos-mesh -n chaos-mesh --set dashboard.create=true --set chaos-daemon.runtime=containerd

```

Verify the Chaos Mesh components are running in the chaos-mesh namespace.

### Port forward the dashboard

```bash
kubectl port-forward -n chaos-mesh svc/chaos-dashboard 2333:2333
```

## Token retrieval

Run the following command:

```bash
kubectl apply -f chaos-mesh/rbac.yaml
```

Get the token to paste into the UI
```bash
kubectl create token account-cluster-manager-euzix
```

View the token
```bash
kubectl describe secrets account-cluster-manager-euzix
```
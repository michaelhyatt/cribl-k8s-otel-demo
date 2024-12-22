# Deploy ngrok agent

## Using helm, add the ngrok repo:
```
helm repo add ngrok https://charts.ngrok.com
```

## Set your environment variables with your ngrok credentials. 
Replace [AUTHTOKEN] and [API_KEY] with your Authtoken and API key.
```bash
export NGROK_AUTHTOKEN=[AUTHTOKEN]
export NGROK_API_KEY=[API_KEY]
```

## Install the ngrok Kubernetes Operator
```bash
helm install ngrok-ingress-controller ngrok/kubernetes-ingress-controller \
  --namespace ngrok-ingress-controller \
  --create-namespace \
  --set credentials.apiKey=${NGROK_API_KEY} \
  --set credentials.authtoken=${NGROK_AUTHTOKEN}
```

## Create a domain in ngrok and update its name in `ngrok/ngrok-manifest.yaml`
Mine looks like the following, yours will be different. So, configure it in Ngrok and update the manifest.
![image](../images/ngrok-endpoint.png)

## Apply the manifest file to your k8s cluster.
```
kubectl apply -f ngrok/ngrok-manifest.yaml
```
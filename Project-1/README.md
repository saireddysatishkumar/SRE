# Kubernetes SRE Project: Blue-Green & Canary Deployments
This project demonstrates deployment strategies (Blue-Green/Canary) and observability using Prometheus, Grafana, and the ELK stack on a resource-constrained local Minikube environment.

## 1. Environment Setup (Optimized for macOS)
To prevent Docker Desktop from crashing, we use a memory-optimized start command.

Bash
### Clean up previous attempts
```
minikube delete
```
### Start with adjusted resources for 10-core/16GB MacBook Pro
```
minikube start --driver=docker --memory 7000 --cpus 4 --disk-size=30g
```
## 2. Deploying the Application
We use a simple http-echo app to visualize traffic shifts.

Bash
### Apply the Blue and Green deployments + Service
```
kubectl apply -f deploy-strategy.yaml
```
## 3. Monitoring & Observability
We install a "Lite" version of the Prometheus stack to save RAM.

Prometheus & Grafana
```Bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

### Install with basic settings to save RAM
```
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --set prometheus.prometheusSpec.resources.requests.memory=1Gi \
  --set grafana.resources.requests.memory=200Mi
```
Accessing Grafana:
```
URL: http://localhost:3000 (after port-forwarding)
```
User: admin

Password: 

Bash
### Run in a separate terminal to access the UI
```
export POD_NAME=$(kubectl --namespace monitoring get pod -l "app.kubernetes.io/name=grafana" -o name)
kubectl --namespace monitoring port-forward $POD_NAME 3000
```
Canary Verification Query
To verify the deployment ratio in Grafana, use the following PromQL:

Code snippet
```
count(kube_pod_container_info{pod=~"myapp-green.*"}) / count(kube_pod_container_info{pod=~"myapp-.*"})
```
## 4. Logging Stack (ELK)
Elasticsearch is configured in single-node mode with a restricted JVM heap to fit within Minikube.

```Bash
helm repo add elastic https://helm.elastic.co
helm repo update
```
### Forcing ES into a very small footprint
```
helm install elasticsearch elastic/elasticsearch \
  --namespace logging --create-namespace \
  --set replicas=1 \
  --set minimumMasterNodes=1 \
  --set resources.requests.memory=1.5Gi \
  --set resources.limits.memory=2Gi \
  --set esJavaOpts="-Xmx1g -Xms1g"
```
```
helm install kibana elastic/kibana --namespace logging
```
Credentials:

Elastic Password: 

## 5. Deployment Strategies
A. Blue-Green Switch
To perform a hard cutover:

Open deploy-strategy.yaml.

Update the myapp-service selector from version: blue to version: green.

Apply changes: 
```
kubectl apply -f deploy-strategy.yaml
```

B. Canary Strategy (Weighted)
To enable traffic splitting (e.g., 25% Green, 75% Blue):

Remove the version label from the Service selector in deploy-strategy.yaml.

Set replicas: 3 for myapp-blue.

Set replicas: 1 for myapp-green.

Apply: 
```
kubectl apply -f deploy-strategy.yaml
```

## 6. SRE FAQ & Troubleshooting
How to verify which pods are serving traffic?
```Bash
kubectl describe svc myapp-service | grep Selector
kubectl get endpoints myapp-service
```
Accessing the app on macOS (Docker Driver)
Standard Minikube IPs are not accessible on macOS. Use a tunnel or port-forward:

Bash
### Method 1 (Recommended)
```
kubectl port-forward svc/myapp-service 8090:80
```
### Method 2 (Minikube Native)
```
minikube service myapp-service
```

# Configure Grafana Dashboard
### "No Data" in Grafana?
On Apple Silicon, cAdvisor metrics can be temperamental. If container_network_receive_bytes_total is empty, use the kube-state-metrics fallback:

Code snippet
# Percentage of Green pods vs Total
count(kube_pod_container_info{pod=~"myapp-green.*"}) / count(kube_pod_container_info{pod=~"myapp-.*"})

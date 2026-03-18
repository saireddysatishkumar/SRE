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
#### port-forwarding prometheus

```
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090
```
### Accessing Grafana:
Run in a separate terminal to access the UI
```
export POD_NAME=$(kubectl --namespace monitoring get pod -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=monitoring" -oname)
```
#or
```
export POD_NAME=$(kubectl --namespace monitoring get pod -l "app.kubernetes.io/name=grafana" -o name)
```
#port-forwarding
```
kubectl --namespace monitoring port-forward $POD_NAME 3000
```

Access URL: http://localhost:3000 (after port-forwarding)

### Get your grafana admin user password by running:
```
  kubectl get secret --namespace monitoring -l app.kubernetes.io/component=admin-secret -o jsonpath="{.items[0].data.admin-password}" | base64 --decode ; echo
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
#### Watch all cluster members come up.
```
  $ kubectl get pods --namespace=logging -l app=elasticsearch-master -w
```
#### Retrieve elastic user's password.
```
  $ kubectl get secrets --namespace=logging elasticsearch-master-credentials -ojsonpath='{.data.password}' | base64 -d
```
#### Access Kibana
Port forward
```
kubectl port-forward -n logging svc/kibana-kibana 5601:5601
```

------------------------------------------------------------------------------
## 6. Log Collection
The Missing Link: Log Collection
Elasticsearch is just a database; it doesn't "reach out" to grab logs. You need a Log Shipper to pick up the logs from your pods and send them to Elasticsearch.

Since we are on a "Lite" memory budget, we should use Filebeat or Fluent Bit.

### Step A: Install Filebeat (The Log Shipper)
Run these commands to deploy a lightweight agent that will find your myapp logs and push them to the Elasticsearch service you already have running.

```Bash
helm repo add elastic https://helm.elastic.co
helm repo update
```
- Install Filebeat and point it to your existing Elasticsearch
```
helm install filebeat elastic/filebeat \
  --namespace logging \
  --set terminationGracePeriod=0 \
  --set daemonset.resources.requests.memory=100Mi \
  --set daemonset.resources.limits.memory=200Mi
```
-  Watch all containers come up.
```
  $ kubectl get pods --namespace=logging -l app=filebeat-filebeat -w
```
### Step B: Verify the "Log Flow"
Wait about 2 minutes, then run this to see if the new indices are created:

- Get the password again if you don't have it handy
```Bash
export ELK_PW=$(kubectl get secrets --namespace logging elasticsearch-master-credentials -ojsonpath='{.data.password}' | base64 -d)
```
- Query Elasticsearch directly to see the list of indices
```
kubectl exec -it -n logging elasticsearch-master-0 -- curl -u elastic:$ELK_PW localhost:9200/_cat/indices?v
```
- Look for a new row starting with filebeat- or logstash-.

------------------------------------------------------------------------------
## 7. Deployment Strategies
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
or run canary.yml. the code change is stored in this file.

Set replicas: 3 for myapp-blue.

Set replicas: 1 for myapp-green.

Apply: 
```
kubectl apply -f deploy-strategy.yaml
or
kubectl apply -f canary.yaml
```

### SRE FAQ & Troubleshooting
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

------------------------------------------------------------------------------
# 8. Configure Grafana Dashboard

## Create trafic for the app so that it will reflect in gafana. otherwise it will not show data in dashboards.
Open a terminal and let it run atleast 15 mins.
```
export URL="http://localhost:8090
while true; do curl -s $URL > /dev/null; sleep 0.1; done
```
## Create Dashboad in Grafana
- Login to Grafana http://127.0.0.1:3000/
- Dashboards > Add  Visualization > Data source (Prometheus - by default) > go Right side 'Panel options' > enter title > Standard Options > Unit > Misc > Percent(0.0-1.0). Save the dashboad
- Click on code, pase following and run queries.
```
count(kube_pod_container_info{pod=~"myapp-green.*"}) / count(kube_pod_container_info{pod=~"myapp-.*"})
```
- Click on 'save dashboard'
- Change time intervel to 'Last 5 mins'.
- It shows the load on green is low.
<img width="1025" height="715" alt="Screenshot 2026-03-17 at 21 01 17" src="https://github.com/user-attachments/assets/2a38068e-2ea9-44e2-b9bf-57d3b7b11aaf" />

 

## Canary Verification
### Now assume that testing is done on green nodes and increase the replicas for green nodes and decrease blue replicas.
```
# Scale the Green deployment from 1 pod to 3 pods
kubectl scale deployment myapp-green --replicas=3
```

### Watch the Graph:
- Within 30 seconds, Prometheus will scrape the new pods.
- The line in Grafana will climb from 0.25 to 0.50 (since you now have 3 Green and 3 Blue pods).

<img width="2050" height="1430" alt="image" src="https://github.com/user-attachments/assets/f9268f5e-65ba-44cc-8154-4af9695c449c" />

### Add a "Threshold" for your Team
Since you are presenting this as a DevOps solution, you can make the graph look more professional:
- On the right-hand sidebar in the Panel Editor, scroll down to Thresholds.
- Click Add Threshold.
- Set the value to 0.3 (30%).
- Set the color to Red.
This visually warns the SRE that the Canary has exceeded its intended 25% limit.

### Verify with kubectl
While waiting for the graph to climb, run this to see the pods coming online in real-time:
```
kubectl get pods -l app=myapp -w
NAME                          READY   STATUS    RESTARTS   AGE
myapp-blue-b57d9f75c-5sb74    1/1     Running   0          5h18m
myapp-blue-b57d9f75c-t29rt    1/1     Running   0          5h18m
myapp-blue-b57d9f75c-xt4hk    1/1     Running   0          5h18m
myapp-green-dc87df5c7-4bpgh   1/1     Running   0          67m
myapp-green-dc87df5c7-mjnpg   1/1     Running   0          67m
myapp-green-dc87df5c7-npxg4   1/1     Running   0          5h18m
```

### Once you are happy with the Green version and your Grafana shows 0.50, you can complete the deployment by "killing" the Blue version:

```Bash
kubectl scale deployment myapp-blue --replicas=0
kubectl get pods -l app=myapp -w                
NAME                          READY   STATUS    RESTARTS   AGE
myapp-green-dc87df5c7-4bpgh   1/1     Running   0          69m
myapp-green-dc87df5c7-mjnpg   1/1     Running   0          69m
myapp-green-dc87df5c7-npxg4   1/1     Running   0          5h20m
```

### Watch the Graph:
- Within 30 seconds, Prometheus will scrape the pods.
- The line in Grafana will climb from 0.50 to 0.100 (since you now have 3 Green and 0 Blue pods).

<img width="1092" height="1191" alt="image" src="https://github.com/user-attachments/assets/a4e36ccf-c5eb-4a0c-a4dd-7e607d8486e2" />



## To verify the deployment ratio in Grafana, use the following PromQL:
Code snippet
```
count(kube_pod_container_info{pod=~"myapp-green.*"}) / count(kube_pod_container_info{pod=~"myapp-.*"})
```

------------------------------------------------------------------------------
# 7. Configuring Elasticserach and Kigana is documented in document ELK.md


------------------------------------------------------------------------------
# 8. Stop all services.
```
minikube stop
```

# 9. Cleanup
To stop the project and reclaim system resources:
1. `helm uninstall monitoring -n monitoring`
2. `helm uninstall elasticsearch -n logging`
3. `minikube delete`
4. `docker system prune` (Optional)

------------------------------------------------------------------------------
# FAQ:
## "No Data" in Grafana?
On Apple Silicon, cAdvisor metrics can be temperamental. If container_network_receive_bytes_total is empty, use the kube-state-metrics fallback:

- Percentage of Green pods vs Total
```
count(kube_pod_container_info{pod=~"myapp-green.*"}) / count(kube_pod_container_info{pod=~"myapp-.*"})
```

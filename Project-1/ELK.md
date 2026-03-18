# ELK SETUP
## 1. Create a Data View (Index Pattern)
Before you can see logs in Kibana, you have to tell it which indices to look at.

1. Access Kibana: 
```bash
kubectl port-forward -n logging svc/kibana-kibana 5601:5601
```
- Run in new terminal to get password
```
kubectl get secrets --namespace=logging elasticsearch-master-credentials -ojsonpath='{.data.password}' | base64 -d
```
2. Open http://localhost:5601 in your browser.

3. Login with user elastic and password. Ignore "%" from above password output.

4. Go to Stack Management > Data Views (or Index Patterns).

<img width="1198" height="619" alt="image" src="https://github.com/user-attachments/assets/3f011451-29f9-4698-9a77-b9bc1a1fca1b" />
<img width="1198" height="619" alt="image" src="https://github.com/user-attachments/assets/284fea80-adc1-44fd-a511-c5b29b93f993" />

5.Click Create data view.

6. Use logstash-* or * (depending on your log collector) to find your app logs.

- Note: If you don't see indices yet, your log forwarder (like Filebeat or Fluentd) might need a restart to find the new namespace.

## 2. Practice Scenario: The "Canary Log Check"
Imagine you just scaled your Green deployment to 25%. You need to verify that Version 2 isn't throwing errors.

Exercise A: Filtering by Version
In the Discover tab, use the KQL (Kibana Query Language) bar:

Search for Version 2: message : "WELCOME TO GREEN"

Filter by Namespace: kubernetes.namespace : "default"

Exercise B: Identify Error Spikes
If you were simulating a failure, you would look for:

level : "error" or status : 500

Goal: Compare the volume of errors between the myapp-blue-* pods and myapp-green-* pods.

## 3. Practice Scenario: The "Traffic Distribution" Visual
Let's build a quick pie chart to see which pods are doing the most work.

Go to Dashboard > Create Dashboard > Create Visualization.

Select Pie Chart.

Set the "Slice by" (Bucket) to Terms aggregation.

Select the field kubernetes.pod.name.keyword.

The Goal: You should see a slice for each of your 4 pods (3 Blue, 1 Green). If one slice is significantly larger, your Kubernetes service load balancing might be uneven.

## 4. SRE Performance Check (MacBook Health)
Since Elasticsearch is a "RAM-eater," let's see how your Minikube is holding up while you play in Kibana:

```Bash
# Check node resource pressure
kubectl top nodes

# Check if Elasticsearch is hitting its 2Gi limit
kubectl top pods -n logging
```

# Kubernetes SRE Project: Blue-Green & Canary Deployments


- terraform/: Having a dedicated environment folder allows you to experiment with your Azure Free Account credits without accidentally breaking your module code.

- kubernetes/: Keeping your  manifests and Application Logic (SRE/Observability).

# Deployment Commands:

## Create AKS cluster
```Bash
brew install azure-cli
az login
cd terraform/environments/azure-lab
terraform init
terraform apply -auto-approve
```

## Deploy manifests on the cluster
1. Open Azure Cloud Shell
Go to the Azure Portal.

Click the Cloud Shell icon (>_) next to the search bar at the top.

If prompted, select Bash.

2. Connect to your AKS Cluster
Since you are already inside Azure, the handshake is instant. Run these two commands:

```Bash
# 1. Get the credentials
az aks get-credentials --resource-group rg-sre-lab --name aks-sre-lab --overwrite-existing

# 2. Verify the nodes are Ready
kubectl get nodes
```

3. Upload your Manifests
Since your files are github, you need to get them into the Cloud Shell.

In the Cloud Shell window, run the command.
```Bash
git clone git clone https://github.com/saireddysatishkumar/SRE.git
```

4. Deploy the Project
Now that the files are in the cloud, just run:

```Bash
# 1. Move to your manifest directory
cd ~/SRE/kubernetes/Project-1/manifests/

# 2. Deploy the Logging "Backend" (Elasticsearch + Fluent-Bit)
kubectl apply -f efb-logging-stack.yaml

# 3. Deploy the Metrics & Dashboard "Frontend"
kubectl apply -f prometheus-grafana.yaml

# 4. Finally, deploy the Application Strategy
kubectl apply -f deploy-strategy.yaml
```


5. Check the Public IP
Since we use the service type to LoadBalancer, Azure is currently talking to its networking stack to give you an IP.

```Bash
kubectl get svc myapp-service --watch
```

6. Enter the EXTERNAL-IP in browswer to access application.
You will see "Welcome to the BLUE Version" in the browser. 

- Note: Now that your cluster is live and your manifests are being applied in the Azure Cloud Shell, you’ve moved from Infrastructure Setup to SRE Operations.


--------------------------------------------------------------------------------------------------------------------------------------------
# SRE
As an SRE, your job isn't just to "run" the code—it's to ensure it is observable, reliable, and scalable. Here is how to explore and configure the core components of your project.

# 1. Explore Traffic Distribution (The "Canary" Test)
Since you deployed both blue and green versions and commented out the version selector in your Service, the Load Balancer is now splitting traffic.

```Bash
# Run a loop to see the traffic split in real-time It can be exexute from local.
while true; do curl -s http://$EXTERNAL_IP; echo; sleep 1; done
```

- What to look for: You should see "Welcome to the BLUE Version" about 66% of the time and "GREEN" 33% of the time (since we have 2 blue replicas and 1 green).

- SRE Goal: This proves your Canary strategy is working before you "cut over" to 100% Green.

# 2. Configure Observability (The "Eyes" of SRE)
You deployed the monitoring-stack.yaml. Now you need to verify that those pods are actually using the isolated hardware we built in Terraform.

Check Pod Placement:

```Bash
kubectl get pods -n monitoring -o wide
```

- Verification: Look at the NODE column. Those pods should be running on the node belonging to the monitor pool, not the systempool.

- SRE Logic: If your app (Blue/Green) has a memory leak, your monitoring tools will stay alive because they are on a different physical VM.

# 3. Explore Logs and Metrics
An SRE survives on data. Let's look at how your app is performing under the hood.

- Streaming Logs: See what your "Green" version is doing:

```Bash
kubectl logs -l version=green -f
```

- Resource Usage: See how much CPU/Memory your pods are actually using (this requires Metrics Server, which is usually on by default in AKS):

```Bash
kubectl top pods
kubectl top nodes
```

# 4. Test Self-Healing (The "Reliability" Test)
One of the 4 Golden Signals of SRE is Availability. Let’s see how Kubernetes handles a failure.

The "Chaos" Test:

- In one terminal window, run the curl loop from Step 1.

- In another window, "kill" one of your blue pods:

```Bash
kubectl delete pod -l version=blue --grace-period=0
```

- Observation: Watch the curl loop. You might see one or two errors, but Kubernetes will immediately start a new pod to maintain your "Desired State" of 2 replicas.

# 5. Configure a "Rollback"
What if the Green version is buggy? An SRE must be able to revert changes instantly.

The Manual Rollback:

1. Edit your deploy-strategy.yaml.

2. Change the Service selector to strictly point back to version: blue.

3. Re-apply: kubectl apply -f deploy-strategy.yaml.

4. Result: 100% of traffic immediately returns to the stable Blue version, even while the Green pods are still running.

---------------------------------------------------------------------------------------------------------------------------
- In the industry, ELK is for Logs (What happened?), while Prometheus/Grafana is for Metrics (How is the system performing?).

-  Because the standard_b2s_v2 nodes have strict memory limits, we swapped the heavy Kibana interface for the lightweight Fluent-Bit agent to prevent OOMKilled crashes. While this means you don't have a built-in web dashboard right now, you still have full visibility. You can use an "SRE Backdoor" by port-forwarding to the Elasticsearch API directly, allowing you to query your Blue/Green logs from your local terminal or browser.

This allows you to see the raw data and cluster health without putting the memory pressure of a full Kibana instance on your standard_b2s_v2 node.

1. The Shipper (Log Ingestion)
Standard ELK: Uses Logstash. It is powerful but runs on Java, which consumes a massive amount of RAM (often 500MB–1GB+) just to stay idle.

Your Slim SRE Stack: Uses Fluent-Bit.

The Defense: Fluent-Bit is written in C and is extremely lightweight. By using it, you saved nearly 90% of the memory typically used by Logstash while still picking up logs from your Blue/Green pods and moving them to the "Warehouse."

2. The Warehouse (Data Storage)
Standard ELK: Uses Elasticsearch.

Your Slim SRE Stack: Also uses Elasticsearch, but with Resource Constraints.

The Defense: We manually capped the "Heap Size" (ES_JAVA_OPTS) to 400MB. This forces the database to operate in a "Small Office" mode. It still stores and indexes your data, but it won't expand its memory usage until it chokes the rest of the node.

3. The Storefront (Visualization)
Standard ELK: Uses Kibana.

Your Slim SRE Stack: Uses (None / API Backdoor).

The Defense: Kibana is a heavy Node.js application. On a 4GB RAM node in New Jersey, Kibana is often the "tipping point" that causes an OOMKill. By removing it, you prioritized System Uptime over a "Pretty UI." You now access the logs through a secure port-forward tunnel (the "SRE Backdoor") directly to the API.

---------------------------------------------------------------------------------------------------------------------------

1. The EFB Stack (Logs)
Purpose: "Tell me exactly what error happened."

Data: String-based text (e.g., 404 Not Found, NullPointerException, User Satish logged in).

Search: You use this when you need to "search" for a specific keyword in your application history.

2. The Prometheus + Grafana Stack (Metrics)
Purpose: "Tell me how fast it happened and how much RAM it used."

Data: Number-based time series (e.g., CPU = 85%, Requests/sec = 100, Memory = 3.2GB).

Alerting: This is what triggers your "Defense" mechanisms (like scaling or paging an engineer) before the node crashes.

- Note: Traces are the third and final piece that is currently "missing" from your stack. We will conver it next project by upgrade server and deploy kibana and telemetry.


# Metrics (grafana-promethius)
1. Port Forwarding (The "Zero-Cost" Tunnel):
```Bash
kubectl port-forward svc/grafana-service -n monitoring 3000:3000
```
you are using "Azure Cloud Shell" (Web Browser)
If you are running this inside a web browser window (https://www.google.com/search?q=shell.azure.com), you cannot simply go to localhost:3000 on your Mac. You must use the Web Preview feature:

Run the kubectl port-forward command above.

Look at the top menu bar of the Cloud Shell window.
<img width="966" height="643" alt="image" src="https://github.com/user-attachments/assets/f724ec6b-280f-4bc8-8d71-d3852187ef4b" />

Click the Web Preview icon (it looks like a little globe or a computer screen with a gear).

Select Configure.

Type 3000 and click Open and browse.

Azure will open a new tab with a unique URL that tunnels directly to your Grafana pod.



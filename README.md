# SRE

```
SRE/
├── terraform/                # Infrastructure as Code (Azure AKS)
│   └── environments/
│       └── azure-lab/        # Your main deployment folder
│           ├── main.tf
│           ├── variables.tf
│           └── terraform.tfvars
├── kubernetes/               # Application & Logic (Your Project-1 files)
│   ├── Project-1/
│   │   ├── manifests/        # Split your big YAMLs into parts
│   │   │   ├── canary.yaml
│   │   │   └── deploy-strategy.yaml
│   │   ├── docs/             # Documentation
│   │   │   ├── ARCHITECTURE.md
│   │   │   ├── ELK.md
│   │   │   └── README.md
│   │   └── helm/             # If you move to Helm charts
└── README.md                 # Root README explaining the whole repo
```


- terraform/environments/azure-lab/: Having a dedicated environment folder allows you to experiment with your Azure Free Account credits without accidentally breaking your module code.

- kubernetes/Project-1/: Keeping your canary.yml and ELK.md documentation here maintains a clear boundary between Infrastructure (Azure) and Application Logic (SRE/Observability).

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
# Deploy Monitoring first
cd SRE/kubernetes/Project-1/manifests/
kubectl apply -f monitoring-stack.yaml

# Deploy the Blue/Green App
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
Component,Goal,Tool/Command
Traffic Mgmt,Controlled Rollouts,Service Selectors / Labels
Isolation,"Prevent ""Noisy Neighbors""",Node Taints & Tolerations
Self-Healing,Maintain Uptime,Deployment Replicas
Visibility,Debugging,kubectl logs / top
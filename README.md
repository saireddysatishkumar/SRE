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
Since we changed the service type to LoadBalancer, Azure is currently talking to its networking stack to give you an IP.

```Bash
kubectl get svc myapp-service --watch
```
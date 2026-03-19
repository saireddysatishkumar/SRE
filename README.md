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

```
cd terraform/environments/azure-lab
terraform init
terraform apply -auto-approve
```

az aks get-credentials --resource-group rg-sre-lab --name aks-sre-lab
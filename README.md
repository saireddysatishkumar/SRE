# SRE

```
SRE/
├── terraform/                # Infrastructure as Code (Azure AKS)
│   ├── modules/
│   │   ├── aks/              # The script I provided earlier
│   │   └── vnet/
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

Deployment Commands:

cd terraform/environments/azure-lab

# Initialize and pull modules
terraform init

# Review the 10+ resources being created
terraform plan

# Deploy to Azure
terraform apply -auto-approve
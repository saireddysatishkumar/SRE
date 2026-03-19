# SRE

```
SRE/
├── kubernetes/               # Application & Logic (Your Project-1 files)
│   ├── Project-1/
│   │   ├── manifests/        # Split your big YAMLs into parts
│   │   │   ├── canary.yaml
│   │   │   └── deploy-strategy.yaml
│   │   ├── docs/             # Documentation
│   │   │   ├── ARCHITECTURE.md
│   │   │   ├── ELK.md
│   │   │   └── README.md
│   │   ├── terraform/                # Infrastructure as Code (Azure AKS)
│   │   │   └── environments/
│   │   │       └── azure-lab/        # Your main deployment folder
│   │   │           ├── main.tf
│   │   │           ├── variables.tf
│   │   │           └── terraform.tfvars
│   │   ├── helm/             # If you move to Helm charts
│   │   └── README.md  
└── README.md                 # Root README explaining the whole repo
```
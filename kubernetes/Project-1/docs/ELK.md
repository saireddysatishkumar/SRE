# ELK
## 1. Access Dashboard: 
```bash
kubectl get svc -n monitoring kibana-service
```
- Run in new terminal to get password
```
kubectl get secrets --namespace=logging elasticsearch-master-credentials -ojsonpath='{.data.password}' | base64 -d
```

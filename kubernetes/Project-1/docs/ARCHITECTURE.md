# System System Architecture & Data Flow
This document outlines the internal mechanics of the SRE observability stack running on Minikube.

## 1. High-Level Overview
The project consists of three primary layers: the Application Layer (Canary/Blue-Green), the Monitoring Layer (Prometheus/Grafana), and the Logging Layer (ELK Stack).


## 2. Monitoring Pipeline (Prometheus & Grafana)
Because this environment runs on Apple Silicon (ARM64) using the Docker driver, the monitoring pipeline is optimized for high-fidelity pod discovery over low-level container metrics.

- Discovery: Prometheus uses the Kubernetes SD (Service Discovery) to find pods with the label app: myapp.

- Data Source (Kube-State-Metrics): Provides "Infrastructure" data (e.g., Is the pod running? How many replicas exist?).

- Data Source (cAdvisor): Provides "Resource" data (e.g., How much CPU/RAM is the container using?).

- Visualization: Grafana queries Prometheus using PromQL to calculate the ratio of Canary vs. Stable pods in real-time.


## 3. Logging Pipeline (ELK Stack)
To stay within the 7GB RAM limit, the ELK stack is deployed in a "Single-Node" footprint.

- Elasticsearch: Acts as the central data store. We use esJavaOpts to cap the JVM heap at 1GB.

- Kibana: Provides the UI to search for specific strings like "WELCOME TO GREEN (v2)" across all pod logs.

- Log Collection: Standard output (stdout) from the http-echo pods is scraped and indexed, allowing for near-instant debugging of deployment failures.

## 4. Canary Traffic Logic
The traffic split is managed via Service Selectors.

- The Service: myapp-service acts as the frontend entry point.

- The Selector: By targeting the label app: myapp (and ignoring the version label), the Service automatically distributes traffic across all matching pods.

- The Weight: The "Weight" of the Canary is determined by the Replica Ratio.

  - 3 Blue Pods + 1 Green Pod = 25% Canary Traffic.

# How to use this documentation
For Troubleshooting: Refer to the Monitoring section to identify which scrape target is failing.

For Scaling: Refer to the Canary Logic section to understand how changing replica counts affects the traffic percentage. & Data Flow

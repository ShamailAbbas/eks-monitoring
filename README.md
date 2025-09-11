# **README.md – Production-Ready EKS + Prometheus + Grafana + Thanos Setup**

## **Project Overview**

This repository provides a **production-ready monitoring stack** on **Amazon EKS (EC2 nodes)** including:

- **Prometheus** for metrics collection
- **Grafana** for visualization
- **Thanos** for long-term storage in S3
- **Persistent storage** via EBS PVCs
- **ALB Ingress** to access Grafana and Prometheus
- **Cluster autoscaling** using Cluster Autoscaler

The setup is optimized for **high-volume metrics** and **long-term retention**, suitable for heavy workloads.

---

## **Folder Structure**

```
eks-monitoring/
├─ README.md
├─ cluster/
│  ├─ create-eks.sh          # Script to create EKS cluster
│  └─ delete-eks.sh          # Script to delete EKS cluster
├─ manifests/
│  ├─ namespaces.yaml        # Kubernetes namespaces
│  ├─ storageclass.yaml      # EBS StorageClass for PVCs
│  ├─ secrets/
│  │   └─ thanos-secret.yaml # Thanos S3 object storage secret
│  ├─ ingress/
│  │   ├─ grafana-ingress.yaml
│  │   └─ prometheus-ingress.yaml
├─ helm-values/
│  ├─ prometheus-values.yaml # Helm values for Prometheus + Thanos
│  └─ grafana-values.yaml    # Helm values for Grafana
├─ scripts/
│  ├─ setup-alb-controller.sh  # Install AWS Load Balancer Controller
│  └─ setup-autoscaler.sh      # Install Cluster Autoscaler
```

---

## **Step 1: Create the EKS Cluster**

**Script:** `cluster/create-eks.sh`

```bash
bash cluster/create-eks.sh
```

**What it does:**

- Creates an **EKS cluster** with a managed EC2 node group
- Uses **OIDC provider** for IAM roles (required for ALB controller & service accounts)
- Node configuration:

  - Type: `m5.large` (adjust based on workload)
  - Min nodes: 3, Max nodes: 6

- Verifies nodes using `kubectl get nodes`

**Customizable values:**

- `CLUSTER_NAME` → your cluster name
- `REGION` → AWS region
- `NODE_TYPE` → instance type for EC2 nodes
- `NODES` → initial number of nodes

---

## **Step 2: Apply Namespaces & StorageClass**

```bash
kubectl apply -f manifests/namespaces.yaml
kubectl apply -f manifests/storageclass.yaml
```

**Explanation:**

- `namespaces.yaml`: Creates `monitoring` namespace for Prometheus and Grafana
- `storageclass.yaml`: Configures EBS **gp3 volumes** for persistent storage of metrics
- PVCs created by Helm charts will use this storage class

**Customizable values:**

- `StorageClass.name` → change from `gp2` if needed
- `type` → `gp2` or `gp3`
- `reclaimPolicy` → `Retain` or `Delete` (Retain is safer for production)

---

## **Step 3: Create Thanos Secret for S3 Remote Storage**

```bash
kubectl apply -f manifests/secrets/thanos-secret.yaml
```

**Explanation:**

- Stores your **S3 credentials** and bucket config as a Kubernetes secret
- Prometheus reads it to push metrics to **S3 via Thanos**
- This allows **massive data retention beyond local PVC limits**

**Customizable values inside secret:**

- `bucket` → your S3 bucket
- `access_key` / `secret_key` → AWS IAM credentials
- `endpoint` → default `s3.amazonaws.com` for AWS

---

## **Step 4: Install AWS Load Balancer Controller**

```bash
bash scripts/setup-alb-controller.sh
```

**Explanation:**

- Creates **IAM role & policy** for ALB controller
- Installs the **Helm chart** for ALB controller
- Enables **ALB ingress** for Grafana & Prometheus

**Customizable values:**

- `CLUSTER_NAME`, `REGION`
- `vpcId` → auto-detected by default

---

## **Step 5: Install Cluster Autoscaler**

```bash
bash scripts/setup-autoscaler.sh
```

**Explanation:**

- Automatically scales EC2 nodes up/down based on workload
- Ensures Prometheus and Grafana always have enough capacity

**Customizable values:**

- `CLUSTER_NAME`, `REGION`

---

## **Step 6: Install Prometheus & Grafana via Helm**

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f helm-values/prometheus-values.yaml

helm install grafana grafana/grafana \
  --namespace monitoring \
  -f helm-values/grafana-values.yaml
```

**Explanation:**

- Prometheus collects metrics from **Kubernetes cluster + applications**
- Grafana visualizes metrics
- Prometheus is configured to use **PVC for persistence** and **Thanos secret for remote storage**

**Customizable values (helm-values):**

- Prometheus retention (`30d`)
- Storage size (`500Gi`)
- Grafana persistence size (`50Gi`)
- Admin user/password

---

## **Step 7: Apply ALB Ingress**

```bash
kubectl apply -f manifests/ingress/grafana-ingress.yaml
kubectl apply -f manifests/ingress/prometheus-ingress.yaml
kubectl get ingress -n monitoring
```

**Explanation:**

- Exposes Grafana & Prometheus on the internet using **AWS ALB**
- You get an **ALB URL** to access dashboards
- No custom domain required

**Customizable values:**

- Annotations for ALB (`scheme: internet-facing` or `internal`)
- Path rules for different services

---

## **Step 8: Verify Deployment**

```bash
kubectl get pods -n monitoring
kubectl get pvc -n monitoring
kubectl get ingress -n monitoring
```

- Ensure all pods are **Running/Ready**
- PVCs are **Bound**
- Ingress shows **ALB DNS names**

---

## **Best Practices / Notes**

1. **Retention & Storage**

   - Prometheus PVC: 500Gi+ recommended for heavy workloads
   - Grafana PVC: 50Gi+
   - Adjust `retention` for Prometheus as needed

2. **Thanos Remote Storage**

   - Allows long-term storage in S3
   - Highly recommended for massive daily metrics

3. **Cluster Autoscaler**

   - Adjust min/max node counts based on workload

4. **Security**

   - Use strong Grafana password
   - Do not hardcode S3 credentials in production; consider **IRSA (IAM Roles for Service Accounts)**

5. **Scaling Nodes**

   - Use bigger EC2 instances (`m5.2xlarge`) if your metrics volume grows

6. **Optional Enhancements**

   - Use **TLS with ALB** for HTTPS
   - Add Prometheus alerting rules
   - Use **Grafana dashboards as code**

---

✅ **Now you have a fully documented, production-ready setup** for:

- EKS cluster with EC2 nodes
- Persistent Prometheus + Grafana
- Thanos S3 remote storage
- ALB ingress access
- Cluster autoscaling

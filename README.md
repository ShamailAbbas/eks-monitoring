# **Production-Ready EKS Monitoring Stack (Prometheus + Grafana + Thanos)**

## **Project Overview**

This repository sets up a **production-ready monitoring stack** on **Amazon EKS (EC2 nodes)** including:

- **Prometheus** – metrics collection from Kubernetes & applications
- **Grafana** – visualization dashboards
- **Thanos** – long-term metrics storage in S3 (persistent & scalable)
- **Persistent storage** via EBS PVCs
- **AWS ALB ingress** – access Grafana & Prometheus externally
- **Cluster autoscaler** – automatic scaling of EC2 nodes

The setup is optimized for **massive daily metrics ingestion**.

---

## **Important Note: S3 Bucket for Thanos**

**Before deploying Prometheus + Thanos**, you **must create an S3 bucket** for long-term storage:

1. **Create an S3 bucket in AWS** (same region as EKS):

```text
Bucket name example: monitoring-metrics-prod
Region: us-east-1
Enable versioning: Optional but recommended
```

2. **Create an IAM user or role** with access to the bucket. Minimum permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::monitoring-metrics-prod",
        "arn:aws:s3:::monitoring-metrics-prod/*"
      ]
    }
  ]
}
```

3. **Update the Thanos secret** with your bucket and credentials:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: thanos-objstore
  namespace: monitoring
type: Opaque
stringData:
  thanos.yaml: |
    type: S3
    config:
      bucket: monitoring-metrics-prod
      endpoint: s3.amazonaws.com
      access_key: YOUR_AWS_ACCESS_KEY
      secret_key: YOUR_AWS_SECRET_KEY
      insecure: false
```

> **Tip:** For production, consider **IRSA (IAM Role for Service Account)** instead of embedding AWS keys in the secret.

---

## **Folder Structure**

```
eks-monitoring/
├─ README.md
├─ cluster/
│  ├─ create-eks.sh
│  └─ delete-eks.sh
├─ manifests/
│  ├─ namespaces.yaml
│  ├─ storageclass.yaml
│  ├─ secrets/
│  │   └─ thanos-secret.yaml
│  ├─ ingress/
│  │   ├─ grafana-ingress.yaml
│  │   └─ prometheus-ingress.yaml
├─ helm-values/
│  ├─ prometheus-values.yaml
│  └─ grafana-values.yaml
├─ scripts/
│  ├─ setup-alb-controller.sh
│  └─ setup-autoscaler.sh
```

---

## **Step-by-Step Deployment**

> **Important:** Follow this order to avoid failures.

### **Step 1: Create the EKS Cluster**

```bash
bash cluster/create-eks.sh
```

- Creates an **EKS cluster** with EC2 nodes
- Configures **OIDC provider** for IAM roles (needed for ALB & Thanos if using IRSA)

**Customizable:**

- `CLUSTER_NAME`, `REGION`, `NODE_TYPE`, `NODES`

**Verify:**

```bash
kubectl get nodes
```

---

### **Step 2: Create Namespace**

```bash
kubectl apply -f manifests/namespaces.yaml
```

- Namespace `monitoring` is required for Prometheus, Grafana, and Thanos secret

---

### **Step 3: Create StorageClass**

```bash
kubectl apply -f manifests/storageclass.yaml
```

- Creates **EBS gp3 StorageClass** for PVCs
- Used by Prometheus (metrics) and Grafana (dashboards)

**Customizable:**

- `parameters.type` → `gp2` or `gp3`
- `reclaimPolicy` → `Retain` recommended
- `volumeBindingMode` → `WaitForFirstConsumer`

---

### **Step 4: Create Thanos Secret**

```bash
kubectl apply -f manifests/secrets/thanos-secret.yaml
```

- Provides **S3 bucket config and credentials** to Prometheus for long-term storage
- Must exist **before installing Prometheus**, otherwise remote storage fails

**Customizable:**

- `bucket` → your S3 bucket name
- `access_key` / `secret_key` → IAM credentials

---

### **Step 5: Install AWS Load Balancer Controller**

```bash
bash scripts/setup-alb-controller.sh
```

- Creates **IAM role & policy** for ALB controller
- Installs ALB controller via Helm
- Required before creating Ingress resources

**Customizable:** `CLUSTER_NAME`, `REGION`, `vpcId`

---

### **Step 6: Install Cluster Autoscaler**

```bash
bash scripts/setup-autoscaler.sh
```

- Automatically scales EC2 nodes based on load
- Ensures sufficient resources for Prometheus & Grafana

**Customizable:** `CLUSTER_NAME`, `REGION`

---

### **Step 7: Install Prometheus & Grafana via Helm**

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

- Prometheus collects cluster + application metrics
- Grafana persists dashboards & configs using PVC
- Thanos pushes metrics to **S3 for long-term storage**

**Customizable values (`helm-values`):**

- `prometheus.prometheusSpec.retention` → 30d default
- `prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage` → 500Gi
- `grafana.persistence.size` → 50Gi
- Admin user/password

---

### **Step 8: Apply ALB Ingress**

```bash
kubectl apply -f manifests/ingress/grafana-ingress.yaml
kubectl apply -f manifests/ingress/prometheus-ingress.yaml
kubectl get ingress -n monitoring
```

- Exposes Grafana & Prometheus externally via **ALB**
- ALB DNS provides access (no domain needed)

**Customizable:**

- `alb.ingress.kubernetes.io/scheme`: `internet-facing` or `internal`
- Path routing rules

---

### **Step 9: Verify Deployment**

```bash
kubectl get pods -n monitoring
kubectl get pvc -n monitoring
kubectl get ingress -n monitoring
```

- Ensure all pods are **Running/Ready**
- PVCs are **Bound**
- Ingress shows **ALB DNS endpoints**

---

## **Best Practices**

1. **Always create resources in this order:**

   1. S3 bucket (Thanos)
   2. Namespace
   3. StorageClass
   4. Thanos secret
   5. ALB Controller
   6. Prometheus + Grafana
   7. Ingress

2. **Prometheus Storage & Retention:**

   - PVC: 500Gi+ for heavy workloads
   - Retention: adjust per metrics volume

3. **Thanos Remote Storage:**

   - Bucket must exist beforehand
   - Allows long-term retention beyond PVC

4. **Cluster Autoscaler:**

   - Ensure min/max nodes sufficient for peak load

5. **Security:**

   - Strong Grafana credentials
   - Consider **IRSA** for S3 instead of embedding keys

6. **Optional Enhancements:**

   - TLS via ALB
   - Prometheus alerting rules
   - Version-controlled Grafana dashboards

---

✅ Following this guide ensures **metrics persist, scale automatically, and are safely stored long-term in S3**.

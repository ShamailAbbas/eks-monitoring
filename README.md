# **Production-Ready EKS Monitoring Stack (Prometheus + Grafana)**

## **Project Overview**

This repository sets up a **production-ready monitoring stack** on **Amazon EKS (EC2 nodes)** including:

- **Prometheus** – metrics collection from Kubernetes & applications
- **Grafana** – visualization dashboards
- **Persistent storage** via EBS PVCs
- **AWS ALB ingress** – access Grafana & Prometheus externally
- **Cluster autoscaler** – automatic scaling of EC2 nodes
- **EBS CSI Driver** – dynamic provisioning of persistent volumes

The setup is optimized for **massive daily metrics ingestion**.

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
│  ├─ ingress/
│  │   ├─ grafana-ingress.yaml
│  │   └─ prometheus-ingress.yaml
├─ helm-values/
│  ├─ prometheus-values.yaml
│  └─ grafana-values.yaml
├─ scripts/
│  ├─ setup-alb-controller.sh
│  ├─ setup-autoscaler.sh
│  └─ setup-csi-driver.sh
```

---

## **Step-by-Step Deployment**

### **Step 1: Create the EKS Cluster**

```bash
bash cluster/create-eks.sh
```

- Creates an **EKS cluster** with EC2 nodes
- Configures **OIDC provider** for IAM roles (needed for ALB, autoscaler, and CSI driver)

**Customizable:** `CLUSTER_NAME`, `REGION`, `NODE_TYPE`, `NODES`

**Verify:**

```bash
kubectl get nodes
```

---

### **Step 2: Create Namespace**

```bash
kubectl apply -f manifests/namespaces.yaml
```

- Namespace `monitoring` is required for Prometheus & Grafana

---

### **Step 3: Install EBS CSI Driver**

```bash
bash scripts/setup-csi-driver.sh
```

- Installs the **AWS EBS CSI Driver**
- Enables **dynamic provisioning** of EBS volumes via PVCs

**Verify:**

```bash
kubectl get pods -n kube-system | grep ebs-csi
```

---

### **Step 4: Create StorageClass**

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

   1. Namespace
   2. EBS CSI Driver
   3. StorageClass
   4. ALB Controller
   5. Prometheus + Grafana
   6. Ingress

2. **Prometheus Storage & Retention:**

   - PVC: 500Gi+ for heavy workloads
   - Retention: adjust per metrics volume

3. **Cluster Autoscaler:**

   - Ensure min/max nodes sufficient for peak load

4. **Security:**

   - Strong Grafana credentials

5. **Optional Enhancements:**

   - TLS via ALB
   - Prometheus alerting rules
   - Version-controlled Grafana dashboards

---

✅ Following this guide ensures **metrics persist, scale automatically, and dashboards remain highly available**.

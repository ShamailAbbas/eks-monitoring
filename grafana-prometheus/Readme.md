# Prometheus + Grafana Monitoring Stack

This folder contains a **production-ready monitoring stack** for Amazon EKS (EC2 nodes).

---

## **Step 1: Create Namespace**

```bash
kubectl apply -f manifests/namespaces.yaml
```

---

## **Step 2: Create StorageClass**

```bash
kubectl apply -f manifests/storageclass.yaml
```

- Used by Prometheus & Grafana PVCs

---

## **Step 3: Install Prometheus & Grafana via Helm**

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

---

## **Step 4: Apply ALB Ingress**

```bash
kubectl apply -f manifests/ingress/grafana-ingress.yaml
kubectl apply -f manifests/ingress/prometheus-ingress.yaml
kubectl get ingress -n monitoring
```

---

## **Step 5: Verify Deployment**

```bash
kubectl get pods -n monitoring
kubectl get pvc -n monitoring
kubectl get ingress -n monitoring
```

---

## **Best Practices**

- Deployment order: Namespace → StorageClass → Prometheus/Grafana → Ingress
- PVC: 500Gi+ recommended for Prometheus
- Strong Grafana credentials
- Optional: TLS, Prometheus alerts, version-controlled dashboards

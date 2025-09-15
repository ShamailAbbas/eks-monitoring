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


kubectl apply -f manifests/alert-rules.yaml

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

## **Grafana Dashboard JSON for node-demo app**

This json will create the dashboard for the mertics defined in the node-demo app. We are mention the four golden signal.

```json
{
  "title": "Node.js Golden Signals",
  "panels": [
    {
      "title": "Request Rate (Traffic)",
      "type": "timeseries",
      "targets": [
        {
          "expr": "rate(http_requests_total[1m])",
          "legendFormat": "{{method}} {{route}} ({{status}})"
        }
      ],
      "gridPos": { "x": 0, "y": 0, "w": 12, "h": 8 }
    },
    {
      "title": "Error Rate",
      "type": "timeseries",
      "targets": [
        {
          "expr": "rate(http_errors_total[1m])",
          "legendFormat": "{{method}} {{route}}"
        }
      ],
      "gridPos": { "x": 12, "y": 0, "w": 12, "h": 8 }
    },
    {
      "title": "Latency (p95)",
      "type": "timeseries",
      "targets": [
        {
          "expr": "histogram_quantile(0.95, sum(rate(http_response_time_seconds_bucket[1m])) by (le, route))",
          "legendFormat": "{{route}} p95"
        }
      ],
      "gridPos": { "x": 0, "y": 8, "w": 12, "h": 8 }
    },
    {
      "title": "Event Loop Lag (Saturation)",
      "type": "timeseries",
      "targets": [
        {
          "expr": "nodejs_eventloop_lag_seconds",
          "legendFormat": "event loop lag"
        }
      ],
      "gridPos": { "x": 12, "y": 8, "w": 12, "h": 8 }
    }
  ],
  "schemaVersion": 27,
  "version": 1,
  "timezone": "browser"
}
```

## **Best Practices**

- Deployment order: Namespace → StorageClass → Prometheus/Grafana → Ingress
- PVC: 500Gi+ recommended for Prometheus
- Strong Grafana credentials
- Optional: TLS, Prometheus alerts, version-controlled dashboards

# ELK Stack Deployment on Kubernetes – Production Guide

This guide will take you through deploying a **production-ready ELK Stack** (Elasticsearch, Logstash, Kibana) on Kubernetes, with **HA, persistent storage, Filebeat log shipping, and ALB ingress for Kibana**. This setup is designed for use with your Node.js app or any other application generating logs.

---

## Prerequisites

1. A **Kubernetes cluster** (EKS recommended for production)
2. `kubectl` installed and configured for your cluster
3. `helm` installed and working
4. Sufficient cluster resources to deploy Elasticsearch, Kibana, and optional Logstash
5. Node.js application generating logs at `/var/log/nodejs/*.log` (or adjust paths in Filebeat)

---

## Step 1: Create Namespace

```bash
kubectl create namespace elk
```

---

## Step 2: Add Elastic Helm Repo

```bash
helm repo add elastic https://helm.elastic.co
helm repo update
```

---

## Step 3: Deploy Elasticsearch

```bash
helm install elasticsearch elastic/elasticsearch -n elk -f elk/elasticsearch-values-prod.yaml
kubectl get pods -n elk
```

### Get Elasticsearch Password

```bash
kubectl get secret elasticsearch-es-elastic-user -n elk -o go-template='{{.data.elastic | base64decode}}'
```

Copy this password for Filebeat and Kibana.

---

## Step 4: Deploy Kibana

```bash
helm install kibana elastic/kibana -n elk -f elk/kibana-values-prod.yaml
kubectl get pods -n elk
```

---

## Step 5: Deploy Logstash (Optional)

```bash
helm install logstash elastic/logstash -n elk -f elk/logstash-values-prod.yaml
kubectl get pods -n elk
```

---

## Step 6: Deploy Filebeat

1. Update password in `elk/filebeat/filebeat-configmap.yaml`:

```yaml
output.elasticsearch:
  username: elastic
  password: "<ELASTIC_PASSWORD>"
```

Replace `<ELASTIC_PASSWORD>` with the value from Step 3a.

2. Apply ConfigMap and DaemonSet:

```bash
kubectl apply -f elk/filebeat/filebeat-configmap.yaml
kubectl apply -f elk/filebeat/filebeat-daemonset.yaml
kubectl rollout restart daemonset filebeat -n elk
```

- Adjust `paths` in Filebeat to match your Node.js logs
- Tune CPU/memory if logs are large

---

## Step 7: Expose Kibana via ALB Ingress

```bash
kubectl apply -f elk/ingress/kibana-ingress.yaml
kubectl get ingress -n elk
```

- Access Kibana via ALB hostname
- ALB annotations configurable for scheme, target type, and ports
- Add HTTPS using AWS ACM if required

---

## Step 8: Verify Deployment

```bash
kubectl get pods -n elk
kubectl get svc -n elk
kubectl get ingress -n elk
```

- Check Kibana UI to confirm logs appear in **Discover**
- Node.js app logs should be visible under `filebeat-*` indices

---

## Step 9: Things You Can Adjust

- **Elasticsearch**

  - `replicas` for master/data nodes
  - CPU/memory/storage
  - Storage class (`gp3`, `gp2`, etc.)

- **Kibana**

  - Number of replicas
  - Access method (`LoadBalancer`, `ClusterIP`, or Ingress)

- **Logstash**

  - Pipeline filters
  - Number of replicas

- **Filebeat**

  - Log paths
  - Index names
  - Resources

- **Ingress**

  - ALB scheme: internet-facing/internal
  - Add HTTPS
  - Path mapping if needed

---

## Step 10: Security Notes

- Use Kubernetes secrets for credentials instead of hardcoding
- Enable TLS/SSL for Elasticsearch in production
- Limit Kibana access using Ingress rules or security groups
- Monitor Elasticsearch pods for CPU/memory usage

---

## Step 11: Logging Flow

1. Node.js app logs → `/var/log/nodejs/*.log`
2. Filebeat DaemonSet reads logs → Elasticsearch
3. Elasticsearch stores logs → indexed by date (`filebeat-*`)
4. Kibana reads logs → visualizes in **Discover**
5. Logstash (optional) can filter/parse logs before Elasticsearch

---

## Deployment Summary Commands

```bash
# Namespace
kubectl create namespace elk

# Helm repo
helm repo add elastic https://helm.elastic.co
helm repo update

# Elasticsearch
helm install elasticsearch elastic/elasticsearch -n elk -f elk/elasticsearch-values-prod.yaml

# Kibana
helm install kibana elastic/kibana -n elk -f elk/kibana-values-prod.yaml

# Logstash (optional)
helm install logstash elastic/logstash -n elk -f elk/logstash-values-prod.yaml

# Filebeat
kubectl apply -f elk/filebeat/filebeat-configmap.yaml
kubectl apply -f elk/filebeat/filebeat-daemonset.yaml
kubectl rollout restart daemonset filebeat -n elk

# Kibana Ingress
kubectl apply -f elk/ingress/kibana-ingress.yaml

# Check resources
kubectl get pods -n elk
kubectl get svc -n elk
kubectl get ingress -n elk
```

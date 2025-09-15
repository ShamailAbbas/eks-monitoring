# Multi-Project Deployment Repository

This repository contains a **full-edge EKS cluster setup** along with modular deployments for monitoring, logging, applications, and GitOps management. Each component has its own folder with a dedicated README for instructions.

---

## **Repository Overview**

- **cluster/**
  Contains scripts to **create, manage, and delete the EKS cluster**, including:

  - EBS CSI driver setup
  - AWS ALB Controller setup
  - Cluster Autoscaler setup
    **Important:** The cluster must be set up first before deploying anything else.
    [See cluster/ README for detailed instructions](https://github.com/ShamailAbbas/eks-monitoring/tree/main/cluster/README.md)

- **prometheus-grafana/**
  Contains a **production-ready monitoring stack** for EKS:

  - Prometheus metrics collection
  - Grafana dashboards
  - Storage configuration via EBS PVCs
    [See prometheus-grafana/ README for deployment instructions](https://github.com/ShamailAbbas/eks-monitoring/tree/main/prometheus-grafana/README.md)

- **elk/**
  Contains the **ELK stack** for logging:

  - Elasticsearch, Logstash, Kibana
  - Filebeat for log collection
    [See elk/ README for deployment instructions](https://github.com/ShamailAbbas/eks-monitoring/tree/main/elk/README.md)

- **node-app/**
  Contains a **Node.js application** with Dockerfile for containerized deployment.
  [See node-app/ README for instructions](https://github.com/ShamailAbbas/eks-monitoring/tree/main/node-app/README.md)

- **argo-cd/**
  Contains **Argo CD deployment manifests and Helm values** for GitOps management:
  - Install Argo CD in the cluster
  - Manage applications declaratively via Git
    [See argo-cd/ README for deployment instructions](https://github.com/ShamailAbbas/eks-monitoring/tree/main/argo-cd/README.md)

---

## **Future Expansion**

- This repository is modular; you can add more folders for new applications, tools, or services.
- Each new folder should contain its own README and any required manifests, scripts, or Helm values.

---

✅ **Usage Summary:**

1. Set up the cluster first using `cluster/` scripts.
2. Deploy monitoring, logging, application stacks, and Argo CD using their respective folders.
3. Follow each folder's README for step-by-step instructions.

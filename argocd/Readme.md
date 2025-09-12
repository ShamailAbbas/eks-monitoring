# Argo CD Deployment (GitOps for EKS)

This folder contains manifests and Helm values to deploy **Argo CD** in your EKS cluster for GitOps-based application management.

---

## **Step 1: Create Namespace**

```bash
kubectl apply -f manifests/argocd-namespace.yaml
```

- Creates the `argocd` namespace

---

## **Step 2: Install Argo CD via Helm**

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

helm install argocd argo/argo-cd \
  --namespace argocd \
  -f helm-values/argocd-values.yaml
```

- Installs Argo CD server, repo server, application controller, and other components
- Customize values in `argocd-values.yaml` for admin password, service type, and ingress

---

## **Step 3: Expose Argo CD Server**

- Option 1: LoadBalancer (default in Helm values)
- Option 2: Ingress (configure your ingress controller)

```bash
kubectl get svc -n argocd
```

- Note the external IP or DNS to access the Argo CD UI

---

## **Step 4: Login to Argo CD**

```bash
kubectl get pods -n argocd
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
```

- Username: `admin`
- Password: retrieved from the command above

---

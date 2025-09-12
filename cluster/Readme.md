# Cluster Setup (EKS)

This folder contains scripts for creating, managing, and deleting the EKS cluster, including setting up the **EBS CSI driver**, **ALB controller**, and **Cluster Autoscaler**.

---

## **Step 1: Create EKS Cluster**

```bash
bash create-eks.sh
```

- Creates **EKS cluster** with EC2 nodes
- Configures **OIDC provider** for IAM roles (ALB, autoscaler, CSI driver)

**Verify Nodes:**

```bash
kubectl get nodes
```

---

## **Step 2: Install EBS CSI Driver**

```bash
bash setup-csi-driver.sh
```

- Enables **dynamic provisioning** of EBS volumes
- Verify installation:

```bash
kubectl get pods -n kube-system | grep ebs-csi
```

---

## **Step 3: Install AWS Load Balancer Controller**

```bash
bash setup-alb-controller.sh
```

- Installs ALB controller via Helm for ingress resources

---

## **Step 4: Install Cluster Autoscaler**

```bash
bash setup-autoscaler.sh
```

- Automatically scales EC2 nodes based on load

---

## **Step 5: Delete Cluster**

```bash
bash delete-eks.sh
```

- Cleans up all cluster resources

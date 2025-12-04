# github_actions_poc2

<img width="915" height="402" alt="image" src="https://github.com/user-attachments/assets/345ebb08-4866-48f3-bc23-5fed5e39d2a9" />



---

# 📌 GitHub Actions → DockerHub Image → Amazon EKS Deployment (POC Guide)

This POC demonstrates deploying an existing **public Docker Hub image** (`devenops641/talesofchina`) to an **Amazon EKS** cluster using **GitHub Actions**.
No Docker build or push step is required.

---

## ✅ **Step 1: Prerequisites**

Before starting, make sure you have:

* An **AWS account**
* A working **EKS Cluster**
* A **node group** attached to the cluster
* `kubectl` access tested locally

  ```bash
  kubectl get nodes
  ```
* A public Docker image:
  `docker pull devenops641/talesofchina`

---

## ✅ **Step 2: Prepare Kubernetes Deployment Manifest**

Create a folder in your repo:

```
k8s/deployment.yaml
```

Add this Deployment (modify port or names if needed):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: talesofchina
  labels:
    app: talesofchina
spec:
  replicas: 2
  selector:
    matchLabels:
      app: talesofchina
  template:
    metadata:
      labels:
        app: talesofchina
    spec:
      containers:
        - name: talesofchina
          image: devenops641/talesofchina:latest
          ports:
            - containerPort: 80
```

Apply it once manually (only first time):

```bash
kubectl apply -f k8s/
```

---

## ✅ **Step 3: Create GitHub Secrets**

Go to:

**GitHub Repo → Settings → Secrets → Actions**

Create:

| Secret Name             | Value Example            |
| ----------------------- | ------------------------ |
| `AWS_ACCESS_KEY_ID`     | Your IAM user access key |
| `AWS_SECRET_ACCESS_KEY` | Your IAM user secret     |
| `AWS_REGION`            | e.g., `ap-south-1`       |
| `EKS_CLUSTER_NAME`      | e.g., `my-eks-cluster`   |

✔ IAM user must have permissions:
`eks:DescribeCluster`, `eks:DescribeNodegroup`, `sts:AssumeRole`, `eks:UpdateClusterConfig`

---

## ✅ **Step 4: Add GitHub Actions Workflow**

Create:

```
.github/workflows/deploy.yml
```

Paste this:

```yaml
name: Pull (DockerHub) -> Scan -> Deploy to EKS

on:
  push:
    branches: [ "main" ]
  workflow_dispatch:
    inputs:
      image_tag:
        description: 'Docker Hub image tag (default: latest)'
        required: false
        default: 'latest'

env:
  IMAGE_REPO: devenops641/talesofchina

jobs:
  scan-and-deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repo
        uses: actions/checkout@v4

      - name: Set image tag
        run: echo "IMAGE_TAG=${{ github.event.inputs.image_tag || 'latest' }}" >> $GITHUB_ENV

      - name: Show image to deploy
        run: echo "Deploying ${{ env.IMAGE_REPO }}:${{ env.IMAGE_TAG }}"

      - name: Trivy scan of DockerHub image
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ env.IMAGE_REPO }}:${{ env.IMAGE_TAG }}
          format: table
          exit-code: 0
          severity: CRITICAL,HIGH

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ secrets.AWS_REGION }}

      - name: Install kubectl
        uses: azure/setup-kubectl@v4
        with:
          version: latest

      - name: Update kubeconfig for EKS
        run: aws eks update-kubeconfig --name ${{ secrets.EKS_CLUSTER_NAME }} --region ${{ secrets.AWS_REGION }}

      - name: Check cluster nodes
        run: kubectl get nodes

      - name: Deploy to EKS (update container image)
        run: |
          kubectl set image deployment/talesofchina talesofchina=${{ env.IMAGE_REPO }}:${{ env.IMAGE_TAG }} --record
          kubectl rollout status deployment/talesofchina --timeout=120s
```

---

## ✅ **Step 5: Push Code to GitHub**

Commit and push:

```bash
git add .
git commit -m "Added EKS deployment workflow"
git push origin main
```

This triggers the CI/CD pipeline.

---

## ✅ **Step 6: Verify Deployment**

Run:

```bash
kubectl get pods -l app=talesofchina
kubectl get svc
kubectl describe deployment talesofchina
```

Once pods are running and healthy, your app is deployed.

---

## 🎉 **POC Completed!**

Your flow is now:

```
GitHub Push → GitHub Actions → Trivy Scan → EKS Deployment (using DockerHub image)
```

No Docker build
No Docker push
No Slack

JUST **pull, scan, deploy** ✔

---


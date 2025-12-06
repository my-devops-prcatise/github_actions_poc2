# github_actions_poc2

<img width="915" height="402" alt="image" src="https://github.com/user-attachments/assets/345ebb08-4866-48f3-bc23-5fed5e39d2a9" />



---

Here is a clean **README.md format** you can paste directly into your repository.
It includes every step you need **before running your GitHub Actions pipeline**.

---

# 🚀 EndHunger CI/CD Pipeline – Setup Guide

### GitHub Actions → SonarQube → Trivy → Terraform (EKS) → Kubernetes Deployment

This guide explains **everything you must set up BEFORE executing the GitHub Actions `deploy.yml` pipeline**.

---

## ✅ **Step 1: Install Terraform on your Ubuntu EC2 (Self-Hosted Runner)**

Your EC2 self-hosted runner must have Terraform installed, because Terraform will create the full EKS infrastructure.

Run the following commands:

```bash
sudo apt-get update
sudo apt-get install -y gnupg software-properties-common curl
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update
sudo apt-get install -y terraform
```

Verify:

```bash
terraform -version
```

---

## ✅ **Step 2: Install AWS CLI (Terraform needs AWS authentication)**

```bash
sudo apt install -y awscli
aws --version
```

Configure it:

```bash
aws configure
```

Enter:

* **AWS Access Key**
* **AWS Secret Key**
* **Region** (ex: `us-east-1`)
* Output: `json`

---

## ✅ **Step 3: Deploy EKS Cluster Using Terraform**

Navigate to your Terraform folder:

```bash
cd terraform/
```

Initialize Terraform:

```bash
terraform init
```

Review resources:

```bash
terraform plan
```

Apply:

```bash
terraform apply
```

Terraform will now create:

* VPC
* Subnets
* NAT Gateway
* EKS Cluster
* Worker Node Group

Wait until it completes successfully.

---

## ✅ **Step 4: Configure kubectl to Connect to EKS**

After Terraform creates the cluster:

```bash
aws eks update-kubeconfig --name <cluster-name> --region <region>
```

Test connection:

```bash
kubectl get nodes
```

If you see worker nodes → you're connected successfully.

---

## ✅ **Step 5: Apply Your Kubernetes Manifests Once**

Before running the CI/CD pipeline, you must manually apply your YAML files one time.

Apply Deployment:

```bash
kubectl apply -f k8s/deployment.yaml
```

Apply Service:

```bash
kubectl apply -f k8s/service.yaml
```

Verify:

```bash
kubectl get all
```

This creates:

* Deployment → `endhunger`
* Service (LoadBalancer)
* 2 pods running
* External LoadBalancer URL

---

## ✅ **Step 6: Verify Kubernetes Pulls the Image**

Kubernetes automatically pulls:

```
devenops641/endhunger:latest
```

Check:

```bash
kubectl describe pod <pod-name> | grep -i "Pulled"
```

---

## ✅ **Step 7: NOW You Can Execute GitHub Actions `deploy.yml`**

The pipeline will perform:

1. **SonarQube Scan** – Code analysis

2. **Trivy Scan** – Docker image vulnerability scan

3. **Apply K8s manifests** (deployment + service)

4. **Rolling update** in EKS using:

   ```
   kubectl set image
   ```

5. **Verify rollout**

6. **Print the running pods**

This works *only after* EKS cluster + deployment + service exist.

---

# 🎉 Final Architecture Flow

```
Developer → GitHub → GitHub Actions (EC2 Self-Hosted Runner)
                  ↓
            SonarQube Scan
                  ↓
             Trivy Image Scan
                  ↓
        Kubernetes Manifests Applied
                  ↓
  Rolling Update to Amazon EKS Deployment
                  ↓
          Verify Pods & Rollout
```

---

If you want the **final README with diagrams included**, just tell me!



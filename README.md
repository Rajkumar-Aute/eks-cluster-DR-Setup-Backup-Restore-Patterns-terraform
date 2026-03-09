# Multi-Region EKS Disaster Recovery Backup Restore with Velero and Terraform

In modern DevSecOps, hoping an AWS region never goes down isn't a disaster recovery strategy. Whether mitigating the blast radius of a regional outage or defending against ransomware, having a verified cross-region recovery plan is critical.

This lab demonstrates how to build a fully automated, Backup Restore disaster recovery setup for Amazon EKS using Terraform and Velero. We will provision a primary cluster in __us-east-1__ and a standby DR cluster in __us-east-2__. By leveraging modern best practices such as EKS Pod Identity and automated StorageClass translation—we ensure stateful workloads can be seamlessly revived in a new region.

## Environment Specifications

* Primary Region: us-east-1
* Disaster Recovery (DR) Region: us-west-2
* Kubernetes Version: 1.35
* Velero Helm Chart Version: 7.2.2

### Step 1: Infrastructure Provisioning

Ensure you have your Terraform configuration files  cloned from GitHub Repo  and switch to the terraform code directory.

Initialize and Apply Terraform: Initialize your working directory to download the required AWS, Kubernetes, and Helm providers, then apply the configuration.

```Bash
git clone https://github.com/Rajkumar-Aute/eks-cluster-DR-Setup-Active-Passive-Patterns-terraform.git
cd eks-cluster-DR-Setup-Active-Passive-Patterns-terraform
terraform init
terraform plan --var-file=learning.tfvars

# to create only primary cluster
# Backup & Restore DR Patterns
terraform apply --var-file=learning.tfvars -var=create_dr_cluster=false
# After taking backup, run below command, it will start second region cluster and test the restore and running applications.
terraform apply --var-file=learning.tfvars
# Type yes when prompted.
```

This provisions your VPCs, EKS clusters, the centralized DR S3 bucket, and deploys Velero to both clusters. Crucially, the DR Velero instance is configured with ReadOnly access to prevent accidental backup corruption.

### Step 2: Deploy a Stateful Test Workload

To validate that our backups capture stateful data and that our DR cluster correctly translates storage classes (gp2 to gp3), we will deploy a test Nginx application.

#### 1. Set Context to Primary Cluster

```Bash
aws eks update-kubeconfig --region us-east-1 --name primary-cluster
```

#### 2. Run the Deployment Script: deploy-test-app.sh in the same directory, make it executable, and run it

Execute it:

```Bash

chmod +x deploy-test-app.sh
sh ./deploy-test-app.sh
```

### Step 3: Trigger a Manual Backup (Primary Region)

While Terraform configured a 15-minute cron schedule, we will trigger a manual backup immediately to validate the workflow.

#### 1. Execute the Backup

```Bash
velero backup create manual-demo-app-backup \
  --include-namespaces demo-app \
  --wait
```

#### 2. Verify the Backup Logs: Ensure the persistent volume was included successfully

```Bash
velero backup describe manual-demo-app-backup --details
```

### Step 4: Execute Disaster Recovery Restore (Secondary Region)

Now, we simulate a failure in us-east-1 and recover the application in us-west-2.

#### 1. Switch Context to the DR Cluster

```Bash
aws eks update-kubeconfig --region us-west-2 --name dr-cluster
```

#### 2. Verify Backup Availability: Ensure the DR Velero instance can read the backup from the central S3 bucket

```Bash

velero backup get
```

(You should see manual-demo-app-backup listed as Completed)

#### 3. Initiate the Restore: Velero will automatically read the change-storage-class-config ConfigMap and convert the gp2 volume to gp3

```Bash
velero restore create manual-demo-app-restore \
  --from-backup manual-demo-app-backup \
  --wait
```

#### 4. Verify Recovery and Storage Translation: Check the namespace, pods, and the dynamically translated PVC

```Bash

velero restore describe manual-demo-app-restore
kubectl get pods -n demo-app
kubectl get pvc -n demo-app
```

### Step 5: Lab Teardown and Cleanup

To avoid unexpected AWS charges, strictly follow these steps to destroy the environment.

#### 1. Clean Up Kubernetes Workloads: Release persistent volumes by deleting the test namespaces

```Bash

# Primary cluster
aws eks update-kubeconfig --region us-east-1 --name primary-cluster
kubectl delete namespace demo-app

# DR cluster
aws eks update-kubeconfig --region us-west-2 --name dr-cluster
kubectl delete namespace demo-app
```

#### 2. Empty the Velero S3 Bucket: Terraform cannot destroy the bucket if it contains objects

```Bash

# Retrieve the bucket name
BUCKET_NAME=$(terraform state show aws_s3_bucket.velero_dr_backups | grep bucket | awk '{print $3}' | tr -d '"')

# Delete all backups (Note: If versioning leaves delete markers, clear them via the AWS Console)
aws s3 rm s3://$BUCKET_NAME --region us-west-2 --recursive
```

#### 3. Destroy the Infrastructure: Tear down all VPCs, Clusters, IAM roles, and Helm releases

```Bash

terraform destroy --var-file=learning.tfvars
# Type yes to confirm. This process usually takes 15-20 minutes.
```

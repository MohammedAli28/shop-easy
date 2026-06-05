# Deployment Guide

## Option 1: 1-Click (Recommended)

1. Fork this repo
2. Add 3 GitHub Secrets (Settings → Secrets → Actions):
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`  
   - `DB_PASSWORD`
3. Go to Actions → **🚀 Deploy Shop Easy** → Run workflow → `deploy`
4. Wait ~15 min → ALB URL in summary

## Option 2: Manual

```bash
# Configure AWS
aws configure --profile shop-easy

# Deploy infra
cd terraform
terraform init
terraform apply -var="db_password=YourPass#2024"

# Load database
RDS=$(terraform output -raw rds_endpoint)
mysql -h $RDS -u admin -pYourPass#2024 shop_easy < ../database/schema.sql

# Push images
AWS_ID=$(aws sts get-caller-identity --query Account --output text)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $AWS_ID.dkr.ecr.us-east-1.amazonaws.com

for svc in product-service order-service frontend; do
  docker build --platform linux/amd64 --provenance=false -t $AWS_ID.dkr.ecr.us-east-1.amazonaws.com/shop-easy/$svc:latest ../$svc
  docker push $AWS_ID.dkr.ecr.us-east-1.amazonaws.com/shop-easy/$svc:latest
done

# Deploy
aws ecs update-service --cluster shop-easy-cluster --service product-service --force-new-deployment
aws ecs update-service --cluster shop-easy-cluster --service order-service --force-new-deployment
aws ecs update-service --cluster shop-easy-cluster --service frontend --force-new-deployment
```

## Cleanup

```bash
cd terraform
terraform destroy -var="db_password=YourPass#2024"
```

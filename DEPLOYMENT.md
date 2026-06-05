# Deployment Guide

## Option 1: 1-Click Deploy (Recommended)

> Add credentials → Click deploy → App is live. No manual AWS setup needed.

### Step 1: Create AWS IAM User

1. AWS Console → **IAM** → **Users** → **Create user**
2. Name: `shop-easy-deployer`
3. **Attach policies directly** → check `AdministratorAccess`
4. Create user → **Security credentials** → **Create access key** → select **CLI**
5. Copy both keys

### Step 2: Add 3 GitHub Secrets

Go to: `https://github.com/<your-user>/shop-easy/settings/secrets/actions`

Click **New repository secret** (NOT environment secret) for each:

| Secret Name | Value |
|-------------|-------|
| `AWS_ACCESS_KEY_ID` | Your access key (starts with `AKIA...`) |
| `AWS_SECRET_ACCESS_KEY` | Your secret key |
| `DB_PASSWORD` | Letters + numbers only, e.g. `ShopEasy2024Strong` |

> ⚠️ DB_PASSWORD rules: No `/`, `@`, `"`, `#`, or spaces. Just letters and numbers.

### Step 3: Deploy

1. Go to **Actions** tab
2. Click **🚀 Deploy Shop Easy**
3. Click **Run workflow** → select `deploy` → click green **Run workflow**
4. Wait ~15 min
5. Check the workflow summary → **App URL** will be there

### Step 4: Destroy (when done)

Same workflow → select `destroy` → Run. Deletes everything including state bucket.

---

## Option 2: Run Locally

```bash
docker compose up --build
```

Open http://localhost:3000

Reset data:
```bash
docker compose down -v && docker compose up --build
```

---

## Option 3: Manual CLI Deploy

```bash
# Configure AWS
aws configure --profile shop-easy

# Create state bucket
export AWS_PROFILE=shop-easy
aws s3 mb s3://shop-easy-tf-state-bucket --region us-east-1

# Provision infrastructure (~15 min)
cd terraform
terraform init
terraform apply -var="db_password=ShopEasy2024Strong"

# Build & push images
AWS_ID=$(aws sts get-caller-identity --query Account --output text)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $AWS_ID.dkr.ecr.us-east-1.amazonaws.com

cd ..
for svc in product-service order-service frontend db-init; do
  docker build --platform linux/amd64 --provenance=false \
    -t $AWS_ID.dkr.ecr.us-east-1.amazonaws.com/shop-easy/$svc:latest ./$svc
  docker push $AWS_ID.dkr.ecr.us-east-1.amazonaws.com/shop-easy/$svc:latest
done

# Run DB migration
SUBNET=$(aws ec2 describe-subnets --filters Name=tag:Name,Values=shop-easy-public-1 --query 'Subnets[0].SubnetId' --output text)
SG=$(aws ec2 describe-security-groups --filters Name=group-name,Values=shop-easy-ecs-sg --query 'SecurityGroups[0].GroupId' --output text)
aws ecs run-task --cluster shop-easy-cluster --task-definition shop-easy-db-init \
  --launch-type FARGATE --network-configuration "awsvpcConfiguration={subnets=[$SUBNET],securityGroups=[$SG],assignPublicIp=ENABLED}"

# Deploy services
aws ecs update-service --cluster shop-easy-cluster --service product-service --force-new-deployment
aws ecs update-service --cluster shop-easy-cluster --service order-service --force-new-deployment
aws ecs update-service --cluster shop-easy-cluster --service frontend --force-new-deployment

# Wait
aws ecs wait services-stable --cluster shop-easy-cluster --services product-service order-service frontend

# Get URL
aws elbv2 describe-load-balancers --names shop-easy-alb --query 'LoadBalancers[0].DNSName' --output text
```

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| "Credentials could not be loaded" | Secrets must be **Repository secrets**, not Environment secrets |
| "MasterUserPassword is not valid" | Use only letters + numbers in DB_PASSWORD (no `#/@"` or spaces) |
| ECS "platform linux/amd64 not found" | Images built with `--platform linux/amd64 --provenance=false` |
| ALB returns 503 | Services starting — wait 2-3 min or check ECS events |
| Products not loading | DB schema not loaded — check db-init task in ECS |
| S3 bucket already exists | Someone else used same name — change in `terraform/backend.tf` |
| Sandbox/lab gets deleted | Use a personal AWS account — labs have resource limits |

---

## Architecture Decisions

| Decision | Reason |
|----------|--------|
| 3 services (not 4-5) | Minimal Fargate tasks, lower cost, stays under sandbox limits |
| No NAT Gateway | ECS in public subnets with `assign_public_ip` — saves $32/mo |
| RDS private | Secure — only ECS security group can access port 3306 |
| DB init via ECS task | Schema loaded internally — no need to expose RDS publicly |
| S3 state auto-created | Zero manual prerequisites — truly 1-click |
| INSERT IGNORE in schema | Idempotent — safe to re-deploy without duplicating data |
| Single workflow file | One place for deploy + destroy — simple to understand |

---

## Cost: ~$57/month

| Resource | Monthly |
|----------|---------|
| ECS Fargate (3 × 0.25 vCPU, 512MB) | ~$25 |
| RDS db.t3.micro | ~$15 |
| ALB | ~$16 |
| ECR + S3 | ~$1 |
| **Total** | **~$57** |

> 💡 Run `destroy` action when not using to stop all charges.

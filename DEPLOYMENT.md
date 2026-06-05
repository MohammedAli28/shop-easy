# Deployment Guide

## Option 1: 1-Click Deploy (Recommended)

> Zero manual AWS setup needed. GitHub Actions handles everything.

### Step 1: Create AWS IAM User

1. Sign in to AWS Console → **IAM** → **Users** → **Create user**
2. Name: `shop-easy-deployer`
3. Attach policy: `AdministratorAccess`
4. Create user → **Security credentials** → **Create access key** → **CLI**
5. Copy Access Key ID and Secret Access Key

### Step 2: Add GitHub Secrets

Go to your repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

| Secret | Value |
|--------|-------|
| `AWS_ACCESS_KEY_ID` | Your IAM access key |
| `AWS_SECRET_ACCESS_KEY` | Your IAM secret key |
| `DB_PASSWORD` | Any strong password (e.g. `MyPass#2024`) |

### Step 3: Deploy

1. Go to **Actions** → **🚀 Deploy Shop Easy**
2. Click **Run workflow** → select `deploy`
3. Wait ~15 min
4. Get ALB URL in the workflow summary ✅

### What happens automatically:
1. Creates S3 bucket for Terraform state
2. Provisions all AWS infra (VPC, ALB, ECS, RDS, ECR)
3. Builds Docker images for all 3 services + db-init
4. Pushes images to ECR
5. Runs DB migration via ECS task (loads schema + seed data)
6. Deploys all services to ECS Fargate
7. Waits for healthy deployment
8. Outputs the live URL

### Destroy

Same workflow → select `destroy` → deletes all resources + state bucket.

---

## Option 2: Run Locally

```bash
docker compose up --build
```

Open http://localhost:3000

To reset data:
```bash
docker compose down -v
docker compose up --build
```

---

## Option 3: Manual AWS Deploy

```bash
# 1. Configure AWS CLI
aws configure --profile shop-easy

# 2. Create S3 state bucket
aws s3 mb s3://shop-easy-tf-state-bucket --region us-east-1

# 3. Deploy infrastructure
cd terraform
terraform init
terraform apply -var="db_password=YourPass#2024"

# 4. Build & push images
AWS_ID=$(aws sts get-caller-identity --query Account --output text)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $AWS_ID.dkr.ecr.us-east-1.amazonaws.com

for svc in product-service order-service frontend db-init; do
  docker build --platform linux/amd64 --provenance=false \
    -t $AWS_ID.dkr.ecr.us-east-1.amazonaws.com/shop-easy/$svc:latest ../$svc
  docker push $AWS_ID.dkr.ecr.us-east-1.amazonaws.com/shop-easy/$svc:latest
done

# 5. Run DB migration
aws ecs run-task --cluster shop-easy-cluster --task-definition shop-easy-db-init \
  --launch-type FARGATE --network-configuration \
  "awsvpcConfiguration={subnets=[SUBNET_ID],securityGroups=[SG_ID],assignPublicIp=ENABLED}"

# 6. Deploy services
aws ecs update-service --cluster shop-easy-cluster --service product-service --force-new-deployment
aws ecs update-service --cluster shop-easy-cluster --service order-service --force-new-deployment
aws ecs update-service --cluster shop-easy-cluster --service frontend --force-new-deployment
```

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| GitHub Actions: "Credentials could not be loaded" | Check secrets are at **Repository** level, not Environment |
| ECS: "platform linux/amd64 not found" | Build with `--platform linux/amd64 --provenance=false` |
| ALB returns 503 | Services not running — check ECS events in console |
| Products not loading | DB schema not loaded — check db-init task logs |
| S3 bucket already exists | Different AWS account — change bucket name in backend.tf |

---

## Architecture Decisions

| Decision | Why |
|----------|-----|
| 3 services (not 5) | Fewer Fargate tasks = less cost, sandbox-friendly |
| No NAT Gateway | ECS in public subnets with `assign_public_ip` saves $32/mo |
| RDS private | Secure — only ECS security group can access port 3306 |
| DB init via ECS task | No need to expose RDS publicly for schema loading |
| S3 backend auto-created | True zero-setup — no manual prerequisites |
| `INSERT IGNORE` in schema | Idempotent — safe to re-run without duplicates |

---

## Cost: ~$57/month

| Resource | Cost |
|----------|------|
| ECS Fargate (3 tasks × 0.25 vCPU) | ~$25 |
| RDS db.t3.micro | ~$15 |
| ALB | ~$16 |
| ECR + S3 | ~$1 |
| **Total** | **~$57/month** |

> Run `destroy` when not using to avoid charges.

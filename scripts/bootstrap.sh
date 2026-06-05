#!/bin/bash
# Run this ONCE before first deployment to create the S3 bucket for Terraform state.
# Usage: ./scripts/bootstrap.sh

set -e

BUCKET="shop-easy-terraform-state"
REGION="us-east-1"
PROFILE="${AWS_PROFILE:-shop-easy}"

echo "Creating S3 bucket for Terraform state..."
aws s3 mb s3://$BUCKET --region $REGION --profile $PROFILE 2>/dev/null || echo "Bucket already exists"

aws s3api put-bucket-versioning --bucket $BUCKET --versioning-configuration Status=Enabled --profile $PROFILE
aws s3api put-bucket-encryption --bucket $BUCKET --server-side-encryption-configuration '{
  "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
}' --profile $PROFILE

echo "✅ S3 bucket '$BUCKET' ready for Terraform state"
echo ""
echo "Next steps:"
echo "1. Add these GitHub secrets to your repo:"
echo "   - AWS_ACCESS_KEY_ID"
echo "   - AWS_SECRET_ACCESS_KEY"
echo "   - DB_PASSWORD"
echo ""
echo "2. Go to Actions → 'Full Deploy (Infra + Services)' → Run workflow"

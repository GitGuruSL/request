# EC2 IAM Role for S3: Secure Migration Guide

Harden the backend by replacing static AWS keys with an EC2 IAM role. Keep the S3 bucket private and use short‑lived presigned URLs from the backend.

## Prerequisites
- AWS account access with permission to manage IAM roles and EC2 instance profiles.
- Backend currently running on EC2 (Ubuntu/Docker) at api.alphabet.lk.
- Bucket name: requestappbucket (adjust if different).

## Overview
1) Create or pick an EC2 IAM role with S3 access (least privilege).
2) Attach the role to the running EC2 instance.
3) Remove static AWS keys from the server env and redeploy.
4) Verify S3 signing and image loading.
5) Optionally tighten bucket/network and use CloudFront.

## 1) Create EC2 role with least privilege (Console)
- IAM → Roles → Create role
  - Trusted entity: AWS service → EC2
  - Permissions: attach a custom inline policy (example below)
  - Name: request-backend-ec2-role (or reuse an existing role with S3 access)

Example least‑privilege S3 policy (edit prefixes as used in your app):
```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadObjects",
      "Effect": "Allow",
      "Action": ["s3:GetObject"],
      "Resource": [
        "arn:aws:s3:::requestappbucket/public/*",
        "arn:aws:s3:::requestappbucket/drivers/*",
        "arn:aws:s3:::requestappbucket/vehicles/*",
        "arn:aws:s3:::requestappbucket/uploads/*"
      ]
    },
    {
      "Sid": "WriteObjects",
      "Effect": "Allow",
      "Action": ["s3:PutObject","s3:DeleteObject"],
      "Resource": [
        "arn:aws:s3:::requestappbucket/drivers/*",
        "arn:aws:s3:::requestappbucket/vehicles/*",
        "arn:aws:s3:::requestappbucket/uploads/*"
      ]
    },
    {
      "Sid": "BucketHead",
      "Effect": "Allow",
      "Action": ["s3:HeadBucket","s3:ListBucket"],
      "Resource": "arn:aws:s3:::requestappbucket"
    }
  ]
}
```

## 2) Attach the role to the running EC2 instance (Console)
- EC2 → Instances → select the backend instance
- Actions → Security → Modify IAM role → pick the role → Update
- Wait ~1 minute

Verify instance sees the role (on the server):
```bash
# Get IMDSv2 token
TOKEN=$(curl -s -X PUT http://169.254.169.254/latest/api/token \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 60")
# Should print a role name (not empty)
curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/iam/security-credentials/
```

## 3) Remove static keys from env and redeploy
Keep these envs: `S3_BUCKET_NAME` and `AWS_REGION` (or `S3_REGION`). Remove static keys.
```bash
sudo sed -i '/^AWS_ACCESS_KEY_ID=/d;/^AWS_SECRET_ACCESS_KEY=/d' \
  /opt/request-backend/production.env
sudo bash /opt/request-backend/deploy/redeploy.sh latest
```

The backend code already supports these env names in `backend/services/s3Upload.js`:
- Bucket: `S3_BUCKET_NAME` or `AWS_S3_BUCKET` (fallback `requestappbucket`)
- Region: `AWS_REGION` or `AWS_S3_REGION` or `S3_REGION` (fallback `us-east-1`)

## 4) Verify
- Health:
```bash
curl -sS http://127.0.0.1:3001/health | jq .
```
- S3 connectivity:
```bash
curl -sS http://127.0.0.1:3001/api/s3/test | jq .
# Expect: { ok: true, bucket: "requestappbucket" }
```
- App images: open Flutter app pages that display S3 images; they should load.

## 5) Optional hardening
- Bucket policy: keep private (Block Public Access enabled). If using VPC Endpoint for S3, restrict by `aws:SourceVpce`.
- Encryption: enable SSE-S3 or SSE-KMS on the bucket. If KMS, grant the role `kms:Encrypt/Decrypt` on the CMK.
- CloudFront + OAC (performance + control):
  - Put CloudFront in front of the bucket; use Origin Access Control.
  - Optionally use CloudFront signed URLs/cookies instead of exposing S3 URLs.
- CORS: if direct browser access needed, restrict origins to your exact domains.
- Logging & rotation: enable CloudTrail for S3 and KMS; rotate old IAM user keys and remove S3 perms from SES-only users.

## Rollback (if needed)
If you must revert quickly:
```bash
# Re-add temporary static keys (not recommended long-term)
echo "AWS_ACCESS_KEY_ID=..." | sudo tee -a /opt/request-backend/production.env
echo "AWS_SECRET_ACCESS_KEY=..." | sudo tee -a /opt/request-backend/production.env
sudo bash /opt/request-backend/deploy/redeploy.sh latest
curl -sS http://127.0.0.1:3001/api/s3/test | jq .
```
Then continue the migration to the role.

---

Last updated: 2025-08-29

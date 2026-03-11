# Tutorial: File Upload to S3

A minimal full-stack app that uploads files from a React frontend, through a FastAPI backend, into an AWS S3 bucket. All AWS infrastructure is provisioned with Terraform.

```
frontend (React + Vite)
    │
    │  multipart/form-data  OR  presigned URL (direct to S3)
    │
    ▼
backend (FastAPI + boto3)  ──────►  AWS S3
    │
    └── credentials from IAM user (local dev)
        or IAM task role (ECS production)
```

## Project Structure

```
tutorial-s3-upload/
├── infra/                 # Terraform — AWS infrastructure
│   ├── main.tf            # Provider config
│   ├── variables.tf       # Input variables
│   ├── s3.tf              # S3 bucket (versioned, CORS)
│   ├── iam.tf             # IAM user + policy (scoped to bucket)
│   └── outputs.tf         # Access key outputs
│
├── backend/               # FastAPI — Python API server
│   ├── main.py            # Endpoints: /upload, /files, /presign, /health
│   ├── config.py          # Pydantic settings (reads .env)
│   ├── s3_client.py       # boto3 S3 client
│   ├── requirements.txt   # Python dependencies
│   └── .env               # AWS credentials (not committed)
│
└── frontend/              # React — browser UI
    ├── src/
    │   ├── App.jsx         # Upload component (server + presigned URL)
    │   └── index.css       # Global styles
    ├── package.json        # npm dependencies
    └── vite.config.js      # Vite config
```

## Prerequisites

- **AWS account** with admin access
- **AWS CLI** configured (`aws configure`)
- **Terraform** >= 1.5 (`terraform -v`)
- **Python** >= 3.10
- **Node.js** >= 18

## Setup

### 1. Infrastructure

```bash
cd infra

# Create terraform.tfvars with your bucket name
cat > terraform.tfvars <<EOF
bucket_name = "my-capstone-uploads-<your-unique-suffix>"
aws_region  = "ap-southeast-1"
EOF

terraform init
terraform apply

# Retrieve credentials for the backend
terraform output access_key_id
terraform output secret_access_key
```

### 2. Backend

```bash
cd backend

python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Create .env with credentials from Terraform output
cat > .env <<EOF
AWS_ACCESS_KEY_ID=<paste access_key_id>
AWS_SECRET_ACCESS_KEY=<paste secret_access_key>
AWS_REGION=ap-southeast-1
S3_BUCKET_NAME=my-capstone-uploads-<your-unique-suffix>
EOF

uvicorn main:app --reload --port 8000
```

API docs available at http://localhost:8000/docs

### 3. Frontend

```bash
cd frontend

npm install
npm run dev
```

Open http://localhost:5173

## Features

- **Upload via server** — file goes Browser → FastAPI → S3 (with progress bar)
- **Upload via presigned URL** — file goes Browser → S3 directly (faster for large files)
- **File listing** — displays all uploaded files with sizes
- **Terraform-managed infra** — S3 bucket, IAM user, least-privilege policy

## Cleanup

```bash
# Empty the bucket
aws s3 rm s3://my-capstone-uploads-<your-suffix> --recursive

# Destroy all AWS resources
cd infra
terraform destroy
```

## How to build and push to ECR

```
cd backend

# Get your ECR repo URL
ECR_URL=$(cd ../infra && terraform output -raw ecr_repository_url)

# Login to ECR
aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin $ECR_URL

# Build the image
docker build -t $ECR_URL:latest .

# Push to ECR
docker push $ECR_URL:latest
```

After pushing, update the ECS service to pull the new image:
```
aws ecs update-service \
  --cluster capstone-tutorial-cluster \
  --service capstone-tutorial-backend-service \
  --force-new-deployment
```

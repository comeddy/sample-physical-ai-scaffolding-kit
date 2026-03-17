#!/bin/bash
# Build OpenPI LoRA training Docker image and push to ECR
#
# Usage:
#   Run from tools/docker directory:
#   cd /path/to/openpi-main/tools/docker
#   ./build_and_push_ecr.sh [AWS_REGION] [AWS_ACCOUNT_ID]
#
#   Examples:
#     ./build_and_push_ecr.sh                           # Use aws configure default region
#     ./build_and_push_ecr.sh us-west-2                 # Specify region only
#     ./build_and_push_ecr.sh us-west-2 123456789012    # Specify both
#
# Environment Variables:
#   IMAGE_TAG (optional): Docker image tag (default: latest)
#   DOCKERFILE_PATH (optional): Path to Dockerfile (default: script's directory)

set -e

# Configuration - Parse command line arguments
AWS_REGION="${1:-${AWS_REGION:-$(aws configure get region 2>/dev/null || echo 'us-east-1')}}"
AWS_ACCOUNT_ID="${2:-${AWS_ACCOUNT_ID:-$(aws sts get-caller-identity --query Account --output text 2>/dev/null)}}"
ECR_REPOSITORY="openpi-lora-train"
IMAGE_TAG="${IMAGE_TAG:-latest}"

# Validate AWS Account ID was retrieved
if [ -z "${AWS_ACCOUNT_ID}" ]; then
    echo "ERROR: Could not determine AWS Account ID"
    echo "Please specify as argument: ./build_and_push_ecr.sh [REGION] [ACCOUNT_ID]"
    echo "Or configure AWS CLI: aws configure"
    exit 1
fi

ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}"

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKERFILE_PATH="${DOCKERFILE_PATH:-${SCRIPT_DIR}/train_lora.Dockerfile}"

# Calculate openpi-main root directory (../../openpi-main from tools/docker)
OPENPI_ROOT="$(cd "${SCRIPT_DIR}/../openpi" && pwd)"

echo "=================================================="
echo "OpenPI LoRA Training - ECR Push Script"
echo "=================================================="
echo "ECR Repository: ${ECR_URI}"
echo "Image Tag: ${IMAGE_TAG}"
echo "Dockerfile: ${DOCKERFILE_PATH}"
echo "OpenPI Root: ${OPENPI_ROOT}"
echo "Build Context: ${OPENPI_ROOT}"
echo ""

# Verify openpi-main directory structure
if [ ! -f "${OPENPI_ROOT}/pyproject.toml" ] || [ ! -f "${OPENPI_ROOT}/uv.lock" ]; then
    echo "ERROR: Cannot find openpi-main root directory"
    echo "Expected location: ${OPENPI_ROOT}"
    echo "Current directory: $(pwd)"
    echo ""
    echo "Please run this script from: /path/to/openpi-main/tools/docker/"
    exit 1
fi

# Step 1: Check if ECR repository exists, create if not
echo "[1/4] Checking ECR repository..."
if ! aws ecr describe-repositories --repository-names "${ECR_REPOSITORY}" --region "${AWS_REGION}" > /dev/null 2>&1; then
    echo "  Creating ECR repository: ${ECR_REPOSITORY}"
    aws ecr create-repository \
        --repository-name "${ECR_REPOSITORY}" \
        --region "${AWS_REGION}" \
        --image-scanning-configuration scanOnPush=true
    echo "  ✓ Repository created"
else
    echo "  ✓ Repository exists"
fi

# Step 2: Authenticate Docker to ECR
echo "[2/4] Authenticating to ECR..."
aws ecr get-login-password --region "${AWS_REGION}" | \
    docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
echo "  ✓ Authentication successful"

# Step 3: Build Docker image
echo "[3/4] Building Docker image for linux/amd64..."
docker build \
    --platform linux/amd64 \
    -t "${ECR_REPOSITORY}:${IMAGE_TAG}" \
    -t "${ECR_URI}:${IMAGE_TAG}" \
    -f "${DOCKERFILE_PATH}" \
    "${OPENPI_ROOT}"
echo "  ✓ Build complete"

# Step 4: Push to ECR
echo "[4/4] Pushing image to ECR..."
docker push "${ECR_URI}:${IMAGE_TAG}"
echo "  ✓ Push complete"

echo ""
echo "=================================================="
echo "✅ Docker image successfully pushed to ECR"
echo "=================================================="
echo "Image URI: ${ECR_URI}:${IMAGE_TAG}"

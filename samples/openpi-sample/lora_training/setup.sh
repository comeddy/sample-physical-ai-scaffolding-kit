#!/bin/bash
# Setup OpenPI environment on HyperPod
# This script will:
#   1. Clone OpenPI repository if needed
#   2. Create required directories
#   3. Prepare environment for Slurm jobs
#
# Usage: ./setup.sh [--hf-token "hf_xxxxx"]

set -e

# Parse command line arguments
HF_TOKEN=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --hf-token)
            HF_TOKEN="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: ./setup.sh [--hf-token \"hf_xxxxx\"]"
            exit 1
            ;;
    esac
done

echo "=================================================="
echo "OpenPI Environment Setup"
echo "=================================================="
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Calculate paths relative to script location
# Script is in: /fsx/ubuntu/openpi-sample/lora_training/
# Base dir is:  /fsx/ubuntu/openpi-sample/
BASE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
OPENPI_ROOT="${BASE_DIR}/openpi"

echo "Script location: ${SCRIPT_DIR}"
echo "Base directory: ${BASE_DIR}"
echo ""

# Clone OpenPI repository if it doesn't exist
if [ ! -d "${OPENPI_ROOT}" ]; then
    echo "📥 Cloning OpenPI repository..."
    cd "${BASE_DIR}"

    if [ -n "${HF_TOKEN}" ]; then
        echo "  Using provided HF_TOKEN for authentication"
        export HF_TOKEN="${HF_TOKEN}"
    fi

    git clone https://github.com/Physical-Intelligence/openpi.git

    if [ $? -eq 0 ]; then
        echo "  ✓ Successfully cloned OpenPI repository"
    else
        echo "  ❌ ERROR: Failed to clone OpenPI repository"
        exit 1
    fi
    echo ""
else
    echo "✓ Found existing OpenPI repository at: ${OPENPI_ROOT}"
    echo ""
fi

# Create required directories
echo "Creating required directories..."

DIRS=(
    "${BASE_DIR}/logs"
    "${BASE_DIR}/.cache"
    "${OPENPI_ROOT}/assets/physical-intelligence/libero"
)

for dir in "${DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo "  ✓ Created: $dir"
    else
        echo "  ✓ Exists: $dir"
    fi
done

echo ""

# Setup environment variables in ~/.bashrc
echo "Setting up environment variables..."
echo ""

# Remove existing OpenPI and Enroot Configuration if it exists
if grep -q "# OpenPI Configuration" ~/.bashrc; then
    echo "  ⚠️  Removing existing OpenPI/Enroot Configuration from ~/.bashrc"
    # Create backup
    cp ~/.bashrc ~/.bashrc.backup
    # Remove entire OpenPI and Enroot configuration block
    grep -v "# OpenPI Configuration" ~/.bashrc | \
    grep -v "# Enroot Configuration" | \
    grep -v "OPENPI_BASE_DIR" | \
    grep -v "OPENPI_PROJECT_ROOT" | \
    grep -v "OPENPI_DATA_HOME" | \
    grep -v "OPENPI_LOG_DIR" | \
    grep -v "export HF_TOKEN=" | \
    grep -v "ENROOT_CACHE_PATH" | \
    grep -v "ENROOT_DATA_PATH" > ~/.bashrc.tmp
    mv ~/.bashrc.tmp ~/.bashrc
fi

# Append new configuration
cat >> ~/.bashrc << EOF
# OpenPI Configuration
export OPENPI_BASE_DIR=${BASE_DIR}
export OPENPI_PROJECT_ROOT=\${OPENPI_BASE_DIR}/openpi
export OPENPI_DATA_HOME=\${OPENPI_BASE_DIR}/.cache
export OPENPI_LOG_DIR=\${OPENPI_BASE_DIR}/logs
EOF

# Add HF_TOKEN if provided
if [ -n "${HF_TOKEN}" ]; then
    echo "export HF_TOKEN=${HF_TOKEN}" >> ~/.bashrc
else
    echo "export HF_TOKEN=" >> ~/.bashrc
fi

# Add Enroot Configuration
cat >> ~/.bashrc << 'EOF'

# Enroot Configuration
export ENROOT_CACHE_PATH=/fsx/enroot
export ENROOT_DATA_PATH=/fsx/enroot/data
EOF

echo "  ✓ Environment variables added to ~/.bashrc"
echo ""

# Display configuration
echo "=================================================="
echo "✅ Setup complete"
echo "=================================================="
echo ""
echo "Environment variables added to ~/.bashrc:"
echo "  OPENPI_BASE_DIR: ${BASE_DIR}"
echo "  OPENPI_PROJECT_ROOT: ${BASE_DIR}/openpi"
echo "  OPENPI_DATA_HOME: ${BASE_DIR}/.cache"
echo "  OPENPI_LOG_DIR: ${BASE_DIR}/logs"
if [ -n "${HF_TOKEN}" ]; then
    echo "  HF_TOKEN: ${HF_TOKEN:0:10}... (set)"
else
    echo "  HF_TOKEN: (not set)"
fi
echo "  ENROOT_CACHE_PATH: /fsx/enroot"
echo "  ENROOT_DATA_PATH: /fsx/enroot/data"

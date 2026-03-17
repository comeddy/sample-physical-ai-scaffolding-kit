#!/bin/bash
#SBATCH --job-name=groot_docker_build
#SBATCH --nodes=1
#SBATCH --output=/fsx/ubuntu/joblog/docker_build_%j.out
#SBATCH --error=/fsx/ubuntu/joblog/docker_build_%j.err

# ================================================
# GROOT Docker Build - Slurm Job Script
# ================================================
# Builds GROOT Docker image on a worker node and pushes to ECR.
#
# Usage:
#   sbatch slurm_build_docker.sh
#
# Prerequisites:
#   - GROOT_HOME must be set in ~/.bashrc
#   - mkdir -p /fsx/ubuntu/joblog
# ================================================

set -e

echo "=================================================="
echo "GROOT Docker Build - Slurm Job"
echo "=================================================="
echo "Job ID: ${SLURM_JOB_ID}"
echo "Node: ${SLURM_NODELIST}"
echo "Start Time: $(date)"
echo "=================================================="

# Verify GROOT_HOME
if [ -z "${GROOT_HOME}" ]; then
    echo "ERROR: GROOT_HOME is not set"
    echo "Please add to ~/.bashrc:"
    echo "  export GROOT_HOME=/fsx/ubuntu/Isaac-GR00T"
    exit 1
fi

# SLURM_SUBMIT_DIR points to the directory where sbatch was invoked.
# BASH_SOURCE[0] resolves to the spool copy, not the original location.
SCRIPT_DIR="${SLURM_SUBMIT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

export JOB_ID="${SLURM_JOB_ID}"

# Run the build script
bash "${SCRIPT_DIR}/build_and_push_ecr.sh"

EXIT_CODE=$?

echo ""
echo "=================================================="
if [ ${EXIT_CODE} -eq 0 ]; then
    echo "Docker build and push completed successfully"
else
    echo "Docker build failed with exit code: ${EXIT_CODE}"
fi
echo "End Time: $(date)"
echo "=================================================="

exit ${EXIT_CODE}
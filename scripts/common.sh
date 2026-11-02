# Shared paths and settings. Sourced by every script.
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
set -a
# shellcheck disable=SC1091
source "$REPO/config.env"
set +a

WORK="${WORK:-/workspace}"
WAN="$WORK/Wan2GP"
VENV="$WAN/.venv"
LOGS="$WORK/logs"
mkdir -p "$LOGS"

# Keep uv's Python on /workspace too, otherwise the venv breaks when the container disk is wiped.
export UV_PYTHON_INSTALL_DIR="$WORK/.uv-python"
export UV_CACHE_DIR="${UV_CACHE_DIR:-/tmp/uv-cache}"
export UV_LINK_MODE=copy
export HF_HOME="$WORK/hf"

# Fix for CUBLAS_STATUS_NOT_INITIALIZED in H3 condition_proj on torch 2.10 + CUDA 13.
export DISABLE_ADDMM_CUDA_LT=1
export TORCH_BLAS_PREFER_CUBLASLT=0

public_url() {
  if [ -n "${RUNPOD_POD_ID:-}" ]; then echo "https://${RUNPOD_POD_ID}-${PORT}.proxy.runpod.net"; else echo "http://localhost:${PORT}"; fi
}

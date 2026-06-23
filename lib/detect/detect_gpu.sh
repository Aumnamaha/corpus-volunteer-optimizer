#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
GPU_JSON=$(python3 "$ROOT/lib/detect/detect_gpu.py" --json 2>/dev/null)
if [ -z "$GPU_JSON" ]; then
  export GPU_BRAND="cpu"; export GPU_DEVICE="cpu"; export GPU_VRAM="0"; return 1
fi
_py() { echo "$GPU_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('$1',''))"; }
export GPU_BRAND=$(_py brand)
export GPU_NAME=$(_py name)
export GPU_VRAM=$(_py vram_gb)
export GPU_DEVICE=$(_py device_str)
export GPU_CUDA_VER=$(_py cuda_version)
export GPU_ROCM_VER=$(_py rocm_version)
export GPU_CC_MAJOR=$(_py compute_capability_major)
export GPU_JSON_FULL="$GPU_JSON"

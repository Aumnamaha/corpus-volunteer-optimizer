#!/usr/bin/env bash
# Re-apply patches after uv tool upgrade corpus-client-cli
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT/lib/utils/colors.sh"
header "Re-applying patches after upgrade"
GPU_JSON=$(python3 "$ROOT/lib/detect/detect_gpu.py" --json 2>/dev/null)
python3 "$ROOT/lib/patch/patch_all.py" --gpu-json "$GPU_JSON"
success "Patches re-applied. Run verify.sh to confirm."

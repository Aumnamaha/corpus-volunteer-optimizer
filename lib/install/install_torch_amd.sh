#!/usr/bin/env bash
set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT/lib/utils/colors.sh"
ROCM_VER="${1:-6.2}"
header "Installing ROCm PyTorch for AMD (ROCm $ROCM_VER)"
ROCM_MAJOR=$(echo "$ROCM_VER" | cut -d. -f1-2)
WHEEL=$(python3 -c "
import json
with open('$ROOT/config/rocm_map.json') as f: m=json.load(f)
r=m.get('$ROCM_MAJOR', list(m.values())[0])
print(r['url'])
")
info "Wheel index: $WHEEL"
CORPUS_PY=$(find "$HOME/.local/share/uv/tools/corpus-client-cli" -name "python*" -type f 2>/dev/null | head -1)
[ -z "$CORPUS_PY" ] && { error "corpus-client-cli not found"; exit 1; }
UV_HTTP_TIMEOUT=300 uv pip install --python "$CORPUS_PY" torch --index-url "$WHEEL" --reinstall
"$CORPUS_PY" -c "
import torch
print(f'  torch  : {torch.__version__}')
print(f'  ROCm   : {torch.cuda.is_available()}')
if torch.cuda.is_available(): print(f'  Device : {torch.cuda.get_device_name(0)}')
"
success "AMD ROCm PyTorch installed"
warn "If unsupported GPU, set: export HSA_OVERRIDE_GFX_VERSION=11.0.0"

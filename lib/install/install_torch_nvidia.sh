#!/usr/bin/env bash
set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT/lib/utils/colors.sh"
CUDA_VER="${1:-unknown}"
header "Installing CUDA PyTorch for NVIDIA (CUDA $CUDA_VER)"
CUDA_MAJOR=$(echo "$CUDA_VER" | cut -d. -f1)
WHEEL=$(python3 -c "
import json
with open('$ROOT/config/cuda_map.json') as f: m=json.load(f)
v='$CUDA_MAJOR'
r=m.get(v)
if not r:
    keys=sorted(m.keys(),key=lambda x:float(x),reverse=True)
    for k in keys:
        if float(k.split('.')[0])<=float(v): r=m[k]; break
print((r or list(m.values())[-1])['url'])
")
info "Wheel index: $WHEEL"
CORPUS_PY=$(find "$HOME/.local/share/uv/tools/corpus-client-cli" -name "python3*" -maxdepth 5 -type f 2>/dev/null | head -1)
[ -z "$CORPUS_PY" ] && { error "corpus-client-cli not found"; exit 1; }
UV_HTTP_TIMEOUT=300 uv pip install --python "$CORPUS_PY" torch --index-url "$WHEEL" --reinstall
"$CORPUS_PY" -c "
import torch
print(f'  torch : {torch.__version__}')
print(f'  CUDA  : {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'  GPU   : {torch.cuda.get_device_name(0)}')
"
success "NVIDIA CUDA PyTorch installed"

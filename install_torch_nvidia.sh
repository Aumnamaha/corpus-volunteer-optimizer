#!/usr/bin/env bash
set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT/lib/utils/colors.sh"
CUDA_VER="${1:-unknown}"
header "Installing CUDA PyTorch for NVIDIA (CUDA $CUDA_VER)"

CUDA_MAJOR=$(echo "$CUDA_VER" | cut -d. -f1)

WHEEL=$(python3 -c "
import json
with open('$ROOT/config/cuda_map.json') as f:
    m = json.load(f)
v = '$CUDA_MAJOR'
r = None
try:
    r = m.get(v)
    if not r:
        keys = sorted(m.keys(), key=lambda x: float(x), reverse=True)
        for k in keys:
            if float(k.split('.')[0]) <= float(v):
                r = m[k]
                break
except (ValueError, TypeError):
    r = None
if not r:
    keys = sorted(m.keys(), key=lambda x: float(x), reverse=True)
    r = m[keys[0]]
print(r['url'])
" 2>/dev/null || echo "https://download.pytorch.org/whl/cu124")

if [ -z "$WHEEL" ]; then
  WHEEL="https://download.pytorch.org/whl/cu124"
  warn "Could not resolve CUDA version -- defaulting to cu124 wheel"
fi

info "Wheel index: $WHEEL"

# Find corpus-client Python -- ONLY look in the tool's bin/ directory,
# never a recursive site-packages search (matches random .py files otherwise).
CORPUS_PY=""
for CANDIDATE in \
  "$HOME/.local/share/uv/tools/corpus-client-cli/bin/python3" \
  "$HOME/.local/share/uv/tools/corpus-client-cli/bin/python" \
  "$HOME/Library/Application Support/uv/tools/corpus-client-cli/bin/python3" \
  "$HOME/Library/Application Support/uv/tools/corpus-client-cli/bin/python"
do
  if [ -f "$CANDIDATE" ] && [ -x "$CANDIDATE" ]; then
    CORPUS_PY="$CANDIDATE"
    break
  fi
done

# Fallback -- read Python path directly from corpus-client's shebang line.
# This is the most reliable method across all platforms/uv versions.
if [ -z "$CORPUS_PY" ]; then
  CORPUS_CLIENT_BIN=$(command -v corpus-client 2>/dev/null || echo "$HOME/.local/bin/corpus-client")
  if [ -f "$CORPUS_CLIENT_BIN" ]; then
    SHEBANG_PATH=$(head -1 "$CORPUS_CLIENT_BIN" | sed 's/#!//')
    if [ -f "$SHEBANG_PATH" ] && [ -x "$SHEBANG_PATH" ]; then
      CORPUS_PY="$SHEBANG_PATH"
    fi
  fi
fi

if [ -z "$CORPUS_PY" ] || [ ! -f "$CORPUS_PY" ]; then
  error "corpus-client-cli Python not found"
  exit 1
fi

info "Using Python: $CORPUS_PY"

UV_HTTP_TIMEOUT=300 uv pip install --python "$CORPUS_PY" torch --index-url "$WHEEL" --reinstall

"$CORPUS_PY" -c "
import torch
print(f'  torch : {torch.__version__}')
print(f'  CUDA  : {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'  GPU   : {torch.cuda.get_device_name(0)}')
"
success "NVIDIA CUDA PyTorch installed"

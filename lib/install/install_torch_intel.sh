#!/usr/bin/env bash
set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT/lib/utils/colors.sh"
header "Installing Intel Extension for PyTorch (Intel Arc)"
CORPUS_PY=$(find "$HOME/.local/share/uv/tools/corpus-client-cli" -name "python*" -type f 2>/dev/null | head -1)
[ -z "$CORPUS_PY" ] && { error "corpus-client-cli not found"; exit 1; }
UV_HTTP_TIMEOUT=300 uv pip install --python "$CORPUS_PY" \
  intel-extension-for-pytorch \
  --extra-index-url https://pytorch-extension.intel.com/release-whl/stable/xpu/us/
"$CORPUS_PY" -c "
import torch, intel_extension_for_pytorch as ipex
print(f'  torch : {torch.__version__}')
print(f'  ipex  : {ipex.__version__}')
print(f'  XPU   : {torch.xpu.is_available()}')
"
success "Intel Arc IPEX installed"

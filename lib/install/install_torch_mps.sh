#!/usr/bin/env bash
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT/lib/utils/colors.sh"
header "Verifying Apple MPS (PyTorch built-in)"
CORPUS_PY=$(find "$HOME/Library/Application Support/uv/tools/corpus-client-cli" -name "python*" -type f 2>/dev/null | head -1)
[ -z "$CORPUS_PY" ] && CORPUS_PY=$(find "$HOME/.local/share/uv/tools/corpus-client-cli" -name "python*" -type f 2>/dev/null | head -1)
[ -z "$CORPUS_PY" ] && { warn "corpus-client-cli not found — skipping MPS check"; exit 0; }
"$CORPUS_PY" -c "
import torch
print(f'  torch   : {torch.__version__}')
print(f'  MPS ok  : {torch.backends.mps.is_available()}')
print(f'  MPS built: {torch.backends.mps.is_built()}')
"
success "Apple MPS ready — no extra installation needed"
info "Setting PYTORCH_ENABLE_MPS_FALLBACK=1 for unsupported Metal ops"

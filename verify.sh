#!/usr/bin/env bash
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT/lib/utils/colors.sh"
header "Verification — corpus-volunteer-optimizer"
CORPUS_PY=$(find "$HOME/.local/share/uv/tools/corpus-client-cli" -name "python*" -type f 2>/dev/null | head -1)
[ -z "$CORPUS_PY" ] && CORPUS_PY=$(find "$HOME/Library/Application Support/uv/tools/corpus-client-cli" -name "python*" -type f 2>/dev/null | head -1)
if [ -z "$CORPUS_PY" ]; then
  error "corpus-client-cli not found"
  exit 1
fi
step "corpus-client binary:"
corpus-client version 2>/dev/null && success "  OK" || warn "  Not in PATH — run: export PATH=\"\$HOME/.local/bin:\$PATH\""
step "Python environment:"
"$CORPUS_PY" --version
step "PyTorch + GPU status:"
"$CORPUS_PY" -c "
import torch, sys
print(f'  torch     : {torch.__version__}')
print(f'  CUDA      : {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'  GPU       : {torch.cuda.get_device_name(0)}')
    print(f'  VRAM      : {torch.cuda.get_device_properties(0).total_memory / 1024**3:.1f} GB')
elif hasattr(torch.backends, 'mps') and torch.backends.mps.is_available():
    print(f'  MPS       : True (Apple Silicon)')
else:
    print(f'  Mode      : CPU only')
"
step "Patch status:"
python3 -c "
import glob
from pathlib import Path
home = Path.home()
patterns = [
    str(home / '.local/share/uv/tools/corpus-client-cli/lib/python*/site-packages/corpus_client_cli/asr.py'),
    str(home / 'Library/Application Support/uv/tools/corpus-client-cli/lib/python*/site-packages/corpus_client_cli/asr.py'),
]
for pat in patterns:
    m = glob.glob(pat)
    if m:
        c = Path(m[0]).read_text()
        print('  asr.py av.open fallback   :', 'APPLIED' if '_strategies' in c else 'NOT APPLIED')
        print('  asr.py _safe_frames       :', 'APPLIED' if '_safe_frames' in c else 'NOT APPLIED')
        break
vp = glob.glob(str(home / '.local/share/uv/tools/corpus-client-cli/lib/python*/site-packages/corpus_client_cli/volunteer.py'))
if vp:
    c = Path(vp[0]).read_text()
    print('  volunteer.py duration     :', 'APPLIED' if 'audio_duration < 100' in c else 'NOT APPLIED')
    print('  volunteer.py segments[:1000]:', 'APPLIED' if 'segments[:1000]' in c else 'NOT APPLIED')
"
echo ""
success "Verification complete — ready to contribute compute!"
info "Run: CORPUS_ASR_NO_COMPILE=1 corpus-client volunteer-compute"

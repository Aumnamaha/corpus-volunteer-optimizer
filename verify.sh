#!/usr/bin/env bash
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT/lib/utils/colors.sh"

# Ensure local bin is in PATH
export PATH="$HOME/.local/bin:$PATH"

# Find corpus-client Python — read shebang from the binary
CORPUS_CLIENT_BIN=$(which corpus-client 2>/dev/null || echo "$HOME/.local/bin/corpus-client")
if [ -f "$CORPUS_CLIENT_BIN" ];
then
  CORPUS_PY=$(head -1 "$CORPUS_CLIENT_BIN" | sed 's/#!//')
else
  CORPUS_PY=""
fi

header "Verification — corpus-volunteer-optimizer"

step "corpus-client binary:"
if command -v corpus-client &>/dev/null || [ -f "$HOME/.local/bin/corpus-client" ]; then
  "$HOME/.local/bin/corpus-client" --skip-update version 2>/dev/null && success "  OK" || \
  corpus-client --skip-update version 2>/dev/null && success "  OK" || \
  warn "  corpus-client found but version check failed"
else
  warn "  Not found — run: export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

step "Python environment:"
if [ -n "$CORPUS_PY" ] && [ -f "$CORPUS_PY" ]; then
  "$CORPUS_PY" --version && success "  OK"
else
  warn "  Python binary not found at: $CORPUS_PY"
fi

step "PyTorch + GPU status:"
if [ -n "$CORPUS_PY" ] && [ -f "$CORPUS_PY" ]; then
  "$CORPUS_PY" -c "
import torch
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
else
  warn "  Skipping torch check"
fi

step "Patch status:"
python3 -c "
import glob
from pathlib import Path
home = Path.home()
patterns = [
    str(home / '.local/share/uv/tools/corpus-client-cli/lib/python*/site-packages/corpus_client_cli/asr.py'),
    str(home / 'Library/Application Support/uv/tools/corpus-client-cli/lib/python*/site-packages/corpus_client_cli/asr.py'),
]
found = False
for pat in patterns:
    m = glob.glob(pat)
    if m:
        c = Path(m[0]).read_text()
        print('  asr.py av.open fallback    :', 'APPLIED ✓' if '_open_strategies' in c else 'NOT APPLIED ✗')
        print('  asr.py _safe_frames        :', 'APPLIED ✓' if '_safe_frames' in c else 'NOT APPLIED ✗')
        found = True
        break
if not found:
    print('  asr.py : not found')

vp = []
for pat in [str(home / '.local/share/uv/tools/corpus-client-cli/lib/python*/site-packages/corpus_client_cli/volunteer.py'),
            str(home / 'Library/Application Support/uv/tools/corpus-client-cli/lib/python*/site-packages/corpus_client_cli/volunteer.py')]:
    vp = glob.glob(pat)
    if vp: break
if vp:
    c = Path(vp[0]).read_text()
    print('  volunteer.py duration      :', 'APPLIED ✓' if 'audio_duration < 100' in c else 'NOT APPLIED ✗')
    print('  volunteer.py segments[:1000]:', 'APPLIED ✓' if 'segments[:1000]' in c else 'NOT APPLIED ✗')
else:
    print('  volunteer.py : not found')
"

echo ""
success "Verification complete!"
info "Run: corpus-client --skip-update volunteer-compute"

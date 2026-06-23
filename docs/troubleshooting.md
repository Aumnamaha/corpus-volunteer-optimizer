# Troubleshooting Guide

## GPU Not Detected

**Symptom:** `GPU: No GPU detected` or tool defaults to CPU

```bash
# Check detection directly
python3 lib/detect/detect_gpu.py

# NVIDIA: check nvidia-smi
nvidia-smi

# AMD: check rocminfo
rocminfo | head -20

# Intel: check lspci
lspci | grep -i "arc\|xe"
```

---

## `Torch not compiled with CUDA enabled`

The corpus-client environment has CPU-only torch. Fix:

```bash
CORPUS_PY=$(find ~/.local/share/uv/tools/corpus-client-cli -name "python*" -type f | head -1)

# Check current torch
$CORPUS_PY -c "import torch; print(torch.__version__)"
# If it shows "+cpu", reinstall:

UV_HTTP_TIMEOUT=300 uv pip install \
  --python "$CORPUS_PY" torch \
  --index-url https://download.pytorch.org/whl/cu132 \
  --reinstall
```

---

## `AssertionError` / torch.compile crash (Blackwell RTX 5000)

```bash
# Fix: disable torch compilation
export CORPUS_ASR_NO_COMPILE=1
CORPUS_ASR_NO_COMPILE=1 corpus-client volunteer-compute
```

Setup.sh adds this to `~/.bashrc` automatically. If it's missing:
```bash
echo 'export CORPUS_ASR_NO_COMPILE=1' >> ~/.bashrc
source ~/.bashrc
```

---

## `CUDA out of memory`

Two causes:

**1. Too many concurrent workers:**
```bash
# Already patched by setup.sh — but verify:
grep "_MAX_GPU_TRANSCRIBE_WORKERS" \
  ~/.local/share/uv/tools/corpus-client-cli/lib/python*/site-packages/corpus_client_cli/asr.py
# Should show = 1 (for <8GB VRAM) or = 2 (for 8GB+)
```

**2. Very long audio file (10+ hours):**
These files hit memory limits even with 1 worker.
The `segments[:1000]` patch helps with upload, but transcription of
10+ hour files may need chunking — a future improvement.

---

## `[Errno 1094995529] Invalid data found`

Corrupt audio file on the server. Our patches handle this:
- `av.open()` 3-strategy fallback tries to open with error tolerance
- `_safe_frames()` skips corrupt packets and continues decoding

If it still fails, the file is unrecoverably corrupt — skip and continue.

---

## `HTTP 422: segments list cannot be empty`

Silent/noise-only audio. The duration filter (`< 100s`) catches most of these.
Files that pass duration check but have no speech will still hit this —
nothing to do, server-side issue.

---

## `HTTP 422: List should have at most 1000 items`

Long audio with >1000 Whisper segments. The `segments[:1000]` patch
truncates before upload. If you still see this, re-apply patches:

```bash
bash reapply.sh
```

---

## Patches not applying after upgrade

```bash
# Re-apply all patches
bash reapply.sh

# Verify
bash verify.sh
```

---

## `502 Bad Gateway` from server

Server overloaded — usually happens when many interns run simultaneously.
Wait 15–30 minutes and retry. Nothing wrong on your end.

---

## PATH issues (`corpus-client: command not found`)

```bash
export PATH="$HOME/.local/bin:$PATH"
# Add permanently:
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

---

## Still stuck?

Run full diagnostics and share the output when asking for help:

```bash
python3 lib/detect/detect_gpu.py
bash verify.sh
corpus-client version
```

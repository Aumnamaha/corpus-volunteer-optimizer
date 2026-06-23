#!/usr/bin/env bash
# write_docs.sh — fills docs/ and patches/ directories
echo "Writing docs and patches..."

# ── docs/nvidia.md ──────────────────────────────────────────────────────────
cat > docs/nvidia.md << 'EOF'
# NVIDIA GPU Setup Guide

## Supported GPUs

| Series | Architecture | CUDA | PyTorch Wheel |
|--------|-------------|------|---------------|
| RTX 5000 (5070, 5080, 5090) | Blackwell | 13.x | cu132 |
| RTX 4000 (4060, 4070, 4080, 4090) | Ada Lovelace | 12.x | cu124/cu126 |
| RTX 3000 (3050, 3060, 3070, 3080, 3090) | Ampere | 12.x | cu121/cu124 |
| RTX 2000 (2060, 2070, 2080) | Turing | 11.8+ | cu118/cu121 |
| GTX 1000 (1060, 1070, 1080) | Pascal | 11.8 | cu118 |

## Quick Setup

```bash
bash setup.sh
```

That's it — setup.sh auto-detects your CUDA version and installs the right wheel.

## RTX 5000 Series (Blackwell) — Special Note

Blackwell GPUs (compute capability 12.0) have a known issue with
`torch.inductor` CUDA graphs. The setup script automatically sets:

```bash
export CORPUS_ASR_NO_COMPILE=1
```

This is written to your `~/.bashrc` automatically. Always run with:

```bash
CORPUS_ASR_NO_COMPILE=1 corpus-client volunteer-compute
```

Or source your bashrc first:

```bash
source ~/.bashrc
corpus-client volunteer-compute
```

## Manual Setup (if setup.sh fails)

```bash
# 1. Check your CUDA version
nvidia-smi

# 2. Install corpus-client-cli
uv tool install git+https://code.swecha.org/corpus/corpus-client-cli

# 3. Find the Python binary
CORPUS_PY=$(find ~/.local/share/uv/tools/corpus-client-cli -name "python*" -type f | head -1)

# 4. Install CUDA torch (replace cu132 with your version)
UV_HTTP_TIMEOUT=300 uv pip install \
  --python "$CORPUS_PY" \
  torch \
  --index-url https://download.pytorch.org/whl/cu132 \
  --reinstall

# 5. Apply patches
python3 lib/patch/patch_all.py

# 6. Verify
bash verify.sh
```

## Expected Performance

| GPU | VRAM | Approx Speed |
|-----|------|-------------|
| RTX 5070 Ti | 12GB | 500–600× real-time |
| RTX 4090 | 24GB | 400–500× real-time |
| RTX 4070 | 12GB | 200–300× real-time |
| RTX 3080 | 10GB | 150–200× real-time |
| RTX 3060 | 12GB | 100–150× real-time |
| RTX 3050 | 4GB | 60–80× real-time |
| RTX 2060 | 6GB | 50–70× real-time |

## Troubleshooting

**`CUDA not available` after install:**
```bash
# Verify torch sees your GPU
$CORPUS_PY -c "import torch; print(torch.cuda.is_available())"
# If False, check nvidia-smi is working first
```

**`CUDA out of memory` on long files:**
Already patched — `_MAX_GPU_TRANSCRIBE_WORKERS = 1` is set automatically for GPUs under 8GB VRAM.

**`torch.compile` crash on RTX 5000:**
Set `CORPUS_ASR_NO_COMPILE=1` — setup.sh does this automatically.
EOF
echo "✓ docs/nvidia.md"

# ── docs/amd.md ─────────────────────────────────────────────────────────────
cat > docs/amd.md << 'EOF'
# AMD GPU Setup Guide

## Supported GPUs (Linux only)

| Series | Architecture | ROCm Version |
|--------|-------------|--------------|
| RX 7900, 7800, 7700, 7600 | RDNA3 | ROCm 6.x |
| RX 6900, 6800, 6700, 6600 | RDNA2 | ROCm 5.x / 6.x |
| RX 5700, 5600, 5500 | RDNA1 | ROCm 5.x (limited) |

> **Windows:** ROCm is not supported on Windows. AMD GPUs on Windows fall back to CPU automatically.
> **macOS:** ROCm is not supported on macOS. Use CPU mode.

## Prerequisites

Install ROCm first (if not already installed):

```bash
# Arch Linux
sudo pacman -S rocm-hip-sdk

# Ubuntu/Debian
wget https://repo.radeon.com/amdgpu-install/6.2/ubuntu/noble/amdgpu-install_6.2.60200-1_all.deb
sudo dpkg -i amdgpu-install_6.2.60200-1_all.deb
sudo amdgpu-install --usecase=rocm

# Add user to render/video groups
sudo usermod -aG render,video $USER
# Log out and back in
```

## Quick Setup

```bash
bash setup.sh
```

## Manual Setup

```bash
# 1. Check ROCm version
rocm-smi --version

# 2. Install corpus-client-cli
uv tool install git+https://code.swecha.org/corpus/corpus-client-cli

# 3. Find Python binary
CORPUS_PY=$(find ~/.local/share/uv/tools/corpus-client-cli -name "python*" -type f | head -1)

# 4. Install ROCm torch
UV_HTTP_TIMEOUT=300 uv pip install \
  --python "$CORPUS_PY" \
  torch \
  --index-url https://download.pytorch.org/whl/rocm6.2 \
  --reinstall

# 5. Apply patches
python3 lib/patch/patch_all.py

# 6. Verify
bash verify.sh
```

## Unsupported GPU Fix

If your AMD GPU is not officially supported by ROCm, try:

```bash
export HSA_OVERRIDE_GFX_VERSION=11.0.0  # for RDNA3
# or
export HSA_OVERRIDE_GFX_VERSION=10.3.0  # for RDNA2
corpus-client volunteer-compute
```

## Troubleshooting

**`No ROCm devices found`:**
```bash
# Check if GPU is visible
rocminfo | grep "Marketing Name"
# Check groups
groups | grep -E "render|video"
```
EOF
echo "✓ docs/amd.md"

# ── docs/intel_arc.md ───────────────────────────────────────────────────────
cat > docs/intel_arc.md << 'EOF'
# Intel Arc GPU Setup Guide

## Supported GPUs

| GPU | VRAM | Architecture |
|-----|------|-------------|
| Arc A770 | 16GB | Xe-HPG |
| Arc A750 | 8GB | Xe-HPG |
| Arc A580 | 8GB | Xe-HPG |
| Arc A380 | 6GB | Xe-HPG |
| Arc A310 | 4GB | Xe-HPG |

> **Linux only** for best results. Windows support via IPEX is experimental.

## Prerequisites

```bash
# Ubuntu/Debian
sudo apt install intel-opencl-icd intel-level-zero-gpu level-zero

# Arch Linux
sudo pacman -S intel-compute-runtime level-zero-loader
```

## Quick Setup

```bash
bash setup.sh
```

## Manual Setup

```bash
# 1. Check GPU is visible
xpu-smi discovery 2>/dev/null || lspci | grep -i "arc\|xe"

# 2. Install corpus-client-cli
uv tool install git+https://code.swecha.org/corpus/corpus-client-cli

# 3. Find Python binary
CORPUS_PY=$(find ~/.local/share/uv/tools/corpus-client-cli -name "python*" -type f | head -1)

# 4. Install Intel Extension for PyTorch
UV_HTTP_TIMEOUT=300 uv pip install \
  --python "$CORPUS_PY" \
  intel-extension-for-pytorch \
  --extra-index-url https://pytorch-extension.intel.com/release-whl/stable/xpu/us/

# 5. Apply patches
python3 lib/patch/patch_all.py

# 6. Verify
bash verify.sh
```

## Expected Performance

Intel Arc is roughly 2–5× faster than CPU for Whisper-based ASR.
Expect ~20–50× real-time transcription speed.

## Troubleshooting

**`XPU not available`:**
```bash
$CORPUS_PY -c "import torch; import intel_extension_for_pytorch as ipex; print(torch.xpu.is_available())"
```

**Slow first run:**
SYCL kernel compilation happens on first inference. Second run will be faster.
`SYCL_CACHE_PERSISTENT=1` is set automatically to cache compiled kernels.
EOF
echo "✓ docs/intel_arc.md"

# ── docs/macos.md ───────────────────────────────────────────────────────────
cat > docs/macos.md << 'EOF'
# macOS Setup Guide

## Apple Silicon (M1 / M2 / M3 / M4)

PyTorch has built-in Metal Performance Shaders (MPS) support for Apple Silicon.
No extra installation needed — setup.sh handles everything.

### Quick Setup

```bash
bash setup.sh
```

### What gets configured

- `PYTORCH_ENABLE_MPS_FALLBACK=1` — handles ops not yet on Metal
- All corpus-client patches applied
- Verified MPS is working

### Expected Performance

| Chip | Approx Speed |
|------|-------------|
| M4 Max | ~80× real-time |
| M3 Pro / Max | ~60× real-time |
| M2 Pro / Max | ~45× real-time |
| M1 Pro / Max | ~35× real-time |
| M1 / M2 / M3 (base) | ~20–30× real-time |

Much faster than CPU-only — worth using even on base M1.

### Run

```bash
corpus-client volunteer-compute
```

No special env vars needed for Apple Silicon.

## Intel Mac

Intel Macs don't have MPS support. Setup falls back to CPU automatically.

```bash
bash setup.sh
# Detects Intel Mac → uses CPU mode
corpus-client volunteer-compute
```

## Troubleshooting

**`MPS not available`:**
```bash
python3 -c "import torch; print(torch.backends.mps.is_available())"
# Requires macOS 12.3+ and Apple Silicon
```

**Slow performance:**
Make sure you're not running under Rosetta 2 (x86 emulation):
```bash
arch  # should print "arm64" not "i386"
```
EOF
echo "✓ docs/macos.md"

# ── docs/windows.md ─────────────────────────────────────────────────────────
cat > docs/windows.md << 'EOF'
# Windows Setup Guide

## Prerequisites

1. **Python 3.11+** — download from [python.org](https://python.org)
   - ✅ Check "Add Python to PATH" during install
2. **uv** — install from PowerShell:
   ```powershell
   powershell -c "irm https://astral.sh/uv/install.ps1 | iex"
   ```
3. **Git** — download from [git-scm.com](https://git-scm.com)

## Quick Setup

Open **PowerShell as Administrator**:

```powershell
git clone https://github.com/Aumnamaha/corpus-volunteer-optimizer
cd corpus-volunteer-optimizer
.\setup.ps1
```

Or double-click `setup.bat`.

## Supported GPUs on Windows

| GPU Brand | Support | Notes |
|-----------|---------|-------|
| NVIDIA | ✅ Full CUDA | Best experience |
| Intel Arc | ✅ IPEX | Experimental |
| AMD | ⚠️ CPU only | ROCm not on Windows |
| No GPU | ✅ CPU | Default fallback |

## NVIDIA on Windows

Ensure you have the latest NVIDIA drivers installed.
The script auto-detects your CUDA version and installs the right wheel.

```powershell
# After setup, run:
corpus-client volunteer-compute
```

For RTX 5000 series (Blackwell), set in PowerShell:
```powershell
$env:CORPUS_ASR_NO_COMPILE = "1"
corpus-client volunteer-compute
```

## Troubleshooting

**`corpus-client` not found after install:**
```powershell
# Add uv tools to PATH
$env:PATH += ";$env:USERPROFILE\.local\bin"
# Or add permanently via System Properties → Environment Variables
```

**PowerShell execution policy error:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**`uv` not found:**
Restart PowerShell after installing uv — it updates PATH on new sessions only.
EOF
echo "✓ docs/windows.md"

# ── docs/troubleshooting.md ─────────────────────────────────────────────────
cat > docs/troubleshooting.md << 'EOF'
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
EOF
echo "✓ docs/troubleshooting.md"

# ── patches/ — reference diffs ──────────────────────────────────────────────
cat > patches/asr_decoder.patch << 'EOF'
# Reference: packet-level fault tolerant decoder patch for asr.py
# Applied by: lib/patch/patch_asr.py (patch_decoder function)
# Replaces: container.decode(audio=0) with _safe_frames(container)
# Effect: Corrupt packets are skipped individually instead of crashing the whole file

# Before:
#   for frame in itertools.chain(container.decode(audio=0), [None]):
#
# After:
#   def _safe_frames(cont):
#       try:
#           for pkt in cont.demux(audio=0):
#               try:
#                   for frm in pkt.decode():
#                       yield frm
#               except Exception:
#                   continue
#       except Exception:
#           pass
#       yield None
#
#   for frame in _safe_frames(container):
EOF
echo "✓ patches/asr_decoder.patch"

cat > patches/asr_open_strategy.patch << 'EOF'
# Reference: 3-strategy av.open() fallback patch for asr.py
# Applied by: lib/patch/patch_asr.py (patch_av_open function)
# Effect: Tries 3 increasingly lenient strategies to open corrupt containers

# Strategy 1: Normal open (default)
# Strategy 2: err_detect=ignore_err (ignore corrupt packets)
# Strategy 3: err_detect=ignore_err + fflags=discardcorrupt (discard corrupt frames)

# Before:
#   container = _av.open(str(audio_path))
#
# After:
#   _strategies = [
#       {},
#       {"options": {"err_detect": "ignore_err"}},
#       {"options": {"err_detect": "ignore_err", "fflags": "discardcorrupt"}},
#   ]
#   container = None; _last_exc = None
#   for _s in _strategies:
#       try:
#           container = _av.open(str(audio_path), **_s)
#           ... (audio stream check)
#           break
#       except RuntimeError: raise
#       except Exception as exc: _last_exc = exc; container = None
#   if container is None:
#       raise RuntimeError(...)
EOF
echo "✓ patches/asr_open_strategy.patch"

cat > patches/volunteer_duration.patch << 'EOF'
# Reference: duration filter patch for volunteer.py
# Applied by: lib/patch/patch_volunteer.py (patch_duration_filter function)
# Effect: Files under 100 seconds are skipped instantly (silent/noise/trash)

# Inserted after _probe_audio_duration() call, before transcription starts:
#
#   if 0 < audio_duration < 100:
#       statuses[i - 1]['state'] = 'failed'
#       statuses[i - 1]['label'] = f'[dim]⏭ Skipped — too short ({audio_duration:.0f}s < 100s)[/dim]'
#       _tick_elapsed()
#       prog.update(task, advance=1)
#       return
EOF
echo "✓ patches/volunteer_duration.patch"

cat > patches/volunteer_segments.patch << 'EOF'
# Reference: segments truncation patch for volunteer.py
# Applied by: lib/patch/patch_volunteer.py (patch_segments_limit function)
# Effect: Truncates segment list to 1000 before upload (server rejects >1000)

# Before:
#   "segments": segments,
#
# After:
#   "segments": segments[:1000],

# Why: The corpus API rejects uploads with more than 1000 segments.
# Long audio files (1+ hour) can produce 5000-15000 segments.
# Truncating keeps the first ~30-40 minutes of transcription.
EOF
echo "✓ patches/volunteer_segments.patch"

echo ""
echo "════════════════════════════════════════════════════════"
echo "  All docs and patches written!"
echo ""
echo "  Now run:"
echo "  git add ."
echo "  git commit -m 'docs: add platform guides and patch references'"
echo "  git push origin main"
echo "════════════════════════════════════════════════════════"

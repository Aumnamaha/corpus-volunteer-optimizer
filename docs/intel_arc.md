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

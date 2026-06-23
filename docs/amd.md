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

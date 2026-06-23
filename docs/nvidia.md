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

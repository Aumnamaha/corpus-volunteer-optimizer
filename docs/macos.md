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

# corpus-volunteer-optimizer

> One command to unlock GPU acceleration for Swecha's corpus-client-cli volunteer compute task.

Built during **Viswam.ai Summer of AI 2026** by Team Abyss.

## What this does

Swecha's `corpus-client-cli` defaults to **CPU inference** even when a GPU is available.
This tool:

1. **Detects your GPU** — NVIDIA, AMD, Intel Arc, Apple Silicon, or CPU
2. **Installs the right PyTorch** — correct CUDA/ROCm wheel for your driver
3. **Applies corpus-client patches** — fault-tolerant decoder, duration filter, segment limit fix
4. **Sets env vars** — GPU-specific flags (e.g. Blackwell needs `CORPUS_ASR_NO_COMPILE=1`)

**Result:** 40–600× faster transcription depending on your GPU vs CPU.

| GPU | Transcription Speed |
|-----|-------------------|
| No GPU (CPU) | ~5× real-time |
| RTX 2060/3050 | ~80× real-time |
| RTX 3080/4070 | ~200× real-time |
| RTX 5070 Ti | ~600× real-time |
| Apple M2 (MPS) | ~30× real-time |

## Quick Start

### Linux / macOS
```bash
git clone https://github.com/Aumnamaha/corpus-volunteer-optimizer
cd corpus-volunteer-optimizer
bash setup.sh
```

### Windows
```powershell
git clone https://github.com/Aumnamaha/corpus-volunteer-optimizer
cd corpus-volunteer-optimizer
.\setup.ps1
# or double-click setup.bat
```

### One-liner (Linux/macOS)
```bash
curl -fsSL https://raw.githubusercontent.com/Aumnamaha/corpus-volunteer-optimizer/main/setup.sh | bash
```

## After Setup

```bash
# NVIDIA Blackwell (RTX 5000 series):
CORPUS_ASR_NO_COMPILE=1 corpus-client volunteer-compute

# All other GPUs:
corpus-client volunteer-compute
```

## Supported Platforms

| Platform | GPU | Status |
|----------|-----|--------|
| Linux | NVIDIA (CUDA 11.8 – 13.x) | ✅ Tested |
| Linux | AMD (ROCm 6.0 – 6.2) | ✅ Supported |
| Linux | Intel Arc (IPEX) | ✅ Supported |
| Linux | No GPU | ✅ CPU fallback |
| macOS | Apple Silicon M1/M2/M3/M4 | ✅ MPS |
| macOS | Intel Mac | ✅ CPU fallback |
| Windows | NVIDIA | ✅ Supported |
| Windows | AMD | ⚠️ CPU (ROCm not on Windows) |
| Windows | Intel Arc | ✅ Supported |

## What gets patched

| Patch | File | Effect |
|-------|------|--------|
| 3-strategy `av.open()` | `asr.py` | Recovers corrupt audio containers |
| `_safe_frames()` decoder | `asr.py` | Skips corrupt packets instead of crashing |
| `_MAX_GPU_TRANSCRIBE_WORKERS` | `asr.py` | Tuned for your VRAM |
| Duration filter `< 100s` | `volunteer.py` | Skips silent/noise files instantly |
| `segments[:1000]` | `volunteer.py` | Fixes server upload limit for long audio |
| GPU env vars | `~/.bashrc` etc | `CORPUS_ASR_NO_COMPILE=1` etc |

## Re-applying after upgrade

If you upgrade corpus-client-cli, patches get wiped. Re-apply with:
```bash
bash reapply.sh   # Linux/macOS
.\reapply.ps1     # Windows
```

## Verify your setup

```bash
bash verify.sh   # Linux/macOS
.\verify.ps1     # Windows
```

## Credits

Patches discovered and battle-tested on:
- Arch Linux + RTX 5070 Ti (Blackwell, CUDA 13.3)
- Fedora Linux + RTX 5070 Ti (CUDA 13.2)

by **Thirunagari Aum Namaha** ([@Aumnamaha](https://github.com/Aumnamaha))
during Viswam.ai SoAI 2026 Internship, Team Abyss.

## License

MIT — use freely, contribute back!

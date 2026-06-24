# corpus-volunteer-optimizer

> One command to unlock GPU acceleration for Swecha's `corpus-client` volunteer compute task.

Built during **Viswam.ai Summer of AI 2026** by **Team Abyss**.

---

## What This Does

Swecha's `corpus-client` defaults to **CPU inference** even when a powerful GPU is sitting idle.
This tool detects your hardware and configures everything automatically:

1. **Detects your GPU** — NVIDIA, AMD, Intel Arc, Apple Silicon, or CPU
2. **Installs the right PyTorch** — correct CUDA/ROCm/IPEX/MPS wheel for your driver
3. **Patches corpus-client** — fault-tolerant decoder, duration filter, segment limit fix
4. **Configures env vars** — GPU-specific flags written to your shell config

**Result:** 10–600× faster transcription depending on your hardware.

---

## Speed Comparison

| Hardware | Mode | Approx Speed |
|----------|------|-------------|
| No GPU (CPU only) | CPU | ~5× real-time |
| Intel Arc A380 | XPU | ~20× real-time |
| Apple M1 / M2 | MPS | ~25–40× real-time |
| GTX 1060 / RTX 2060 | CUDA | ~50–80× real-time |
| RTX 3050 / 3060 | CUDA | ~80–120× real-time |
| RTX 3080 / 4070 | CUDA | ~150–250× real-time |
| RTX 4090 | CUDA | ~400–500× real-time |
| RTX 5070 Ti / 5080 / 5090 | CUDA | ~500–600× real-time |
| AMD RX 6700 / 7800 XT | ROCm | ~60–120× real-time |

---

## Supported Platforms

| OS | GPU | Status | Notes |
|----|-----|--------|-------|
| Linux | NVIDIA GTX 900+ / RTX 2000–5000 | ✅ Tested | CUDA 11.8 – 13.x |
| Linux | AMD RX 5000 / 6000 / 7000 | ✅ Supported | ROCm 6.x |
| Linux | Intel Arc A-series | ✅ Supported | IPEX |
| Linux | No GPU | ✅ CPU fallback | Works out of the box |
| macOS | Apple Silicon M1 / M2 / M3 / M4 | ✅ Supported | MPS built into PyTorch |
| macOS | Intel Mac | ✅ CPU fallback | No GPU acceleration |
| Windows | NVIDIA GTX 900+ / RTX 2000–5000 | ✅ Supported | CUDA auto-detected |
| Windows | Intel Arc | ✅ Supported | IPEX |
| Windows | AMD GPU | ⚠️ CPU fallback | ROCm not on Windows |

---

## Quick Start

### Prerequisites

- Python 3.11+ installed
- `uv` installed — if not: `curl -LsSf https://astral.sh/uv/install.sh | sh`
- Git installed
- Internet connection

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

### One-liner (Linux / macOS)

```bash
curl -fsSL https://raw.githubusercontent.com/Aumnamaha/corpus-volunteer-optimizer/main/setup.sh | bash
```

---

## After Setup

### Login to Corpus API

```bash
corpus-client login
# Environment: prod
# Phone: +91XXXXXXXXXX
# Password: your password
```

### Start Contributing Compute

```bash
# All GPUs except Blackwell (RTX 5000 series):
corpus-client volunteer-compute

# NVIDIA Blackwell only (RTX 5070 Ti, 5080, 5090):
CORPUS_ASR_NO_COMPILE=1 corpus-client volunteer-compute
```

> **Note on auto-updates:**
> `corpus-client` auto-updates itself on every run. An auto-update wipes our patches.
> corpus-client v0.1.1 removed the `--skip-update` flag. If patches break after an auto-update, run: `bash reapply.sh`
> If an update does happen, re-apply patches with `bash reapply.sh`.

### Check Your Compute Hours

```bash
corpus-client profile
```

---

## What Gets Patched

| Patch | File | Problem Solved |
|-------|------|----------------|
| 3-strategy `av.open()` | `asr.py` | Corrupt audio containers crash entire batch |
| `_safe_frames()` decoder | `asr.py` | Corrupt packets kill transcription mid-file |
| `_MAX_GPU_TRANSCRIBE_WORKERS` | `asr.py` | CUDA OOM on concurrent long files |
| Duration filter `< 100s` | `volunteer.py` | Silent/noise files waste GPU time |
| `segments[:1000]` truncation | `volunteer.py` | Server rejects uploads with >1000 segments |
| GPU env vars | `~/.bashrc` etc | `CORPUS_ASR_NO_COMPILE=1` for Blackwell, ROCm flags for AMD |

---

## Re-applying Patches After Upgrade

If `corpus-client` auto-updates and patches get wiped:

```bash
bash reapply.sh     # Linux / macOS
.\reapply.ps1       # Windows
```

---

## Verify Your Setup

```bash
bash verify.sh      # Linux / macOS
.\verify.ps1        # Windows
```

Expected output:
```
✓ corpus-client installed
✓ PyTorch with CUDA/MPS/ROCm/XPU
✓ GPU detected: NVIDIA GeForce RTX XXXX
✓ asr.py patched
✓ volunteer.py patched
Ready to contribute compute!
```

---

## Platform-Specific Guides

- [NVIDIA GPU Guide](docs/nvidia.md) — CUDA setup, Blackwell fix, RTFx benchmarks
- [AMD GPU Guide](docs/amd.md) — ROCm setup, unsupported GPU workarounds
- [Intel Arc Guide](docs/intel_arc.md) — IPEX setup, XPU device
- [Apple Silicon Guide](docs/macos.md) — MPS setup, M1–M4 performance
- [Windows Guide](docs/windows.md) — PowerShell setup, PATH configuration
- [Troubleshooting Guide](docs/troubleshooting.md) — Common errors and fixes

---

## GPU-Specific Notes

### NVIDIA RTX 5000 Series (Blackwell)
Compute capability 12.0 — `torch.compile` CUDA graphs crash on this architecture.
Setup automatically sets `CORPUS_ASR_NO_COMPILE=1` in your shell config.

### NVIDIA RTX 4000 / 3000 / 2000 Series
Fully supported. Setup auto-detects CUDA version and installs the matching wheel.

### NVIDIA GTX 1000 Series
Supported via CUDA 11.8 wheels. Expect ~30–60× real-time speed.

### AMD GPU (Linux only)
ROCm must be installed before running setup. See [AMD Guide](docs/amd.md).
Windows AMD GPUs fall back to CPU — ROCm is Linux-only.

### Intel Arc (Linux / Windows)
Uses Intel Extension for PyTorch (IPEX) with `device=xpu`.
Roughly 3–5× faster than CPU for ASR tasks.

### Apple Silicon (M1 / M2 / M3 / M4)
Uses Metal Performance Shaders (MPS) — built into PyTorch, no extra install.
Unified memory means no VRAM limit — full chip memory available.

### No GPU / CPU Only
Fully supported fallback. corpus-client works on CPU — just slower.
All other patches (fault-tolerant decoder, duration filter, segments limit) still apply.

---

## Troubleshooting

**patches break after update:**
```bash
bash reapply.sh
```

**`corpus-client: command not found`:**
```bash
export PATH="$HOME/.local/bin:$PATH"
```

**`CUDA not available` after setup:**
```bash
bash verify.sh  # shows exactly what's wrong
```

Full troubleshooting guide: [docs/troubleshooting.md](docs/troubleshooting.md)

---

## Project Structure

```
corpus-volunteer-optimizer/
├── setup.sh / setup.ps1 / setup.bat   ← Main entry point
├── reapply.sh / reapply.ps1           ← Re-patch after upgrade
├── verify.sh / verify.ps1             ← Post-install verification
├── lib/
│   ├── detect/detect_gpu.py           ← Cross-platform GPU detector
│   ├── install/install_torch_*.sh     ← Per-brand PyTorch installer
│   └── patch/patch_*.py               ← corpus-client patchers
├── config/
│   ├── cuda_map.json                  ← CUDA version → wheel mapping
│   ├── rocm_map.json                  ← ROCm version → wheel mapping
│   └── gpu_quirks.json                ← GPU-specific env var flags
├── docs/                              ← Platform guides
└── tests/                             ← Detection + patch tests
```

---

## Contributing

Found a bug? Tested on a new GPU? Please contribute!

- Add CUDA/ROCm version support → edit `config/cuda_map.json` or `config/rocm_map.json`
- Add GPU quirk → edit `config/gpu_quirks.json`
- Fix a patch → edit `lib/patch/patch_asr.py` or `lib/patch/patch_volunteer.py`

See [CONTRIBUTING.md](CONTRIBUTING.md) for full guide.

**Test results from different hardware are especially valuable** — open an issue with your
`bash verify.sh` output and we'll add it to the benchmarks table.

---

## Test Results

| Tester | OS | GPU | Speed | Status |
|--------|----|----|-------|--------|
| Aum | Arch Linux | RTX 5070 Ti (12GB) | ~600× | ✅ |
| Aum | Fedora Linux | RTX 5070 Ti (12GB) | ~500× | ✅ |
| — | Arch Linux | AMD GPU | pending | 🔄 |
| — | Windows | Intel Arc | pending | 🔄 |
| — | Linux | No dGPU (CPU) | pending | 🔄 |
| — | Linux | RTX 3050 | pending | 🔄 |

*Running tests across different hardware — results will be updated.*

---

## Credits

Patches discovered and battle-tested on Arch Linux + Fedora with RTX 5070 Ti (Blackwell, CUDA 13.3)
during **Viswam.ai SoAI 2026** internship.

**Author:** Thirunagari Aum Namaha ([@Aumnamaha](https://github.com/Aumnamaha))
**Team:** Abyss — SoAI 2026, GITAM University Hyderabad

---

## License

[MIT](LICENSE) — free to use, modify, and share.
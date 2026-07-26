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

## ⚡ Step 0 — Install Prerequisites (Do This First!)

Before cloning the repo, make sure these are installed.
**If any of these are missing, `setup.sh` will fail.**

### Check what you have

```bash
git --version      # need 2.0+
python3 --version  # need 3.11+
uv --version        # need 0.5+
```

### Install missing tools

#### Ubuntu / Debian / Linux Mint
```bash
sudo apt update
sudo apt install -y git python3 python3-pip curl
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.bashrc
```

#### Arch Linux / Manjaro
```bash
sudo pacman -S git python
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.bashrc
```

#### Fedora / RHEL / CentOS
```bash
sudo dnf install -y git python3 curl
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.bashrc
```

#### macOS
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install git python
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.zshrc
```

#### Windows (PowerShell — Run as Administrator)
```powershell
winget install --id Git.Git -e --source winget
winget install --id Python.Python.3.12 -e --source winget
powershell -ExecutionPolicy Bypass -c "irm https://astral.sh/uv/install.ps1 | iex"
# Restart PowerShell after installing
```

Verify all three work before proceeding: `git --version`, `python3 --version`, `uv --version`.

---

## 🚀 Quick Start

### Step 1 — Clone the repo

```bash
git clone https://github.com/Aumnamaha/corpus-volunteer-optimizer
cd corpus-volunteer-optimizer
```

### Step 2 — Run setup (one command does everything)

```bash
bash setup.sh          # Linux / macOS
.\setup.ps1             # Windows (PowerShell)
# or double-click setup.bat on Windows
```

### Step 3 — Login to Corpus API

```bash
corpus-client login
# Environment: prod
# Phone: +91XXXXXXXXXX
# Password: your password
```

### Step 4 — Start Contributing Compute

```bash
# Single batch, unattended (recommended — no prompts):
corpus-client volunteer-compute --always

# Keep running continuously until you stop it (Ctrl+C):
bash run_forever.sh     # Linux / macOS
.\run_forever.ps1        # Windows
```

> **Why `run_forever`?** `--always` clears one batch (usually 20 records) then exits.
> `run_forever.sh` / `.ps1` loops it automatically so you don't have to keep re-running it by hand.

### One-liner (Linux / macOS)

```bash
curl -fsSL https://raw.githubusercontent.com/Aumnamaha/corpus-volunteer-optimizer/main/setup.sh | bash
```

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
| macOS | Apple Silicon M1 / M2 / M3 / M4 | ✅ Tested | MPS built into PyTorch |
| macOS | Intel Mac | ✅ CPU fallback | No GPU acceleration |
| Windows | NVIDIA GTX 900+ / RTX 2000–5000 | ✅ Tested | CUDA auto-detected |
| Windows | Intel Arc | ✅ Supported | IPEX |
| Windows | AMD GPU | ⚠️ CPU fallback | ROCm not on Windows |

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

**On auto-updates:** `corpus-client` auto-updates itself on every run, which can wipe these patches.
If patches break after an update, just re-apply them:

```bash
bash reapply.sh     # Linux / macOS
.\reapply.ps1        # Windows
```

---

## Verify Your Setup

```bash
bash verify.sh      # Linux / macOS
.\verify.ps1         # Windows
```

Expected output:
```
✓ corpus-client installed
✓ PyTorch with CUDA/MPS/ROCm/XPU
✓ GPU detected: NVIDIA GeForce RTX XXXX
✓ asr.py av.open fallback    : APPLIED
✓ asr.py _safe_frames        : APPLIED
✓ volunteer.py duration      : APPLIED
✓ volunteer.py segments[:1000]: APPLIED
Verification complete!
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

**`git: command not found` / `uv: command not found` / `python3: command not found`:**
See the Prerequisites section above.

**`corpus-client: command not found` after setup:**
```bash
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

**`CUDA` shows as `unknown` during GPU detection:**
Newer NVIDIA drivers (610+) print `CUDA UMD Version:` instead of the older `CUDA Version:` label.
This is handled automatically as of the latest `detect_gpu.py` — if you still see `unknown`,
pull the latest repo changes (`git pull origin main`) and re-run `setup.sh`.

**`CUDA not available` after setup:**
```bash
bash verify.sh  # shows exactly what's wrong
```

**patches break after `corpus-client` auto-update:**
```bash
bash reapply.sh
```

**`--always` stops after one batch:**
That's expected — `--always` only clears one pledge batch. Use the continuous loop instead:
```bash
bash run_forever.sh     # Linux / macOS
.\run_forever.ps1         # Windows
```

Full troubleshooting guide: [docs/troubleshooting.md](docs/troubleshooting.md)

---

## Project Structure

```
corpus-volunteer-optimizer/
├── setup.sh / setup.ps1 / setup.bat   ← Main entry point
├── run_forever.sh / run_forever.ps1   ← Continuous compute loop
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
- Test on new hardware → open an issue with your `bash verify.sh` output

See [CONTRIBUTING.md](CONTRIBUTING.md) for full guide.

---

## Test Results

All entries below are **verified via the actual repo scripts** (`setup.sh` / `setup.ps1` end-to-end),
not manual patching.

| Tester | OS | GPU | Status |
|--------|----|----|--------|
| Aum | Arch Linux | RTX 5070 Ti (12GB), CUDA 13.3 | ✅ ~600× real-time |
| Aum | Fedora Linux | RTX 5070 Ti (12GB), CUDA 13.3, driver 610.43 | ✅ Clean `setup.sh` run, all patches verified |
| Aum | Windows 11 | RTX 5070 Ti (12GB), CUDA 13.3 | ✅ Clean `setup.ps1` run, all patches verified |
| Aum | macOS (M1, 8GB) | Apple Silicon MPS | ✅ Clean `setup.sh` run, all patches verified |
| — | Arch Linux | AMD GPU | 🔄 pending |
| — | Windows | Intel Arc | 🔄 pending |
| — | Linux | No dGPU (CPU) | 🔄 pending |
| — | Linux | RTX 3050 | 🔄 pending |

*3 operating systems fully verified. Still gathering results for AMD, Intel Arc, CPU-only, and older NVIDIA cards.*

---

## Credits

Patches discovered and battle-tested on Arch Linux, Fedora, Windows, and macOS with
RTX 5070 Ti (Blackwell, CUDA 13.3) and Apple M1 during **Viswam.ai SoAI 2026** internship.

**Author:** Thirunagari Aum Namaha ([@Aumnamaha](https://github.com/Aumnamaha))
**Team:** Abyss — SoAI 2026, GITAM University Hyderabad

---

## License

[MIT](LICENSE) — free to use, modify, and share.

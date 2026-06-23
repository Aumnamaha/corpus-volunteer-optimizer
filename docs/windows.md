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

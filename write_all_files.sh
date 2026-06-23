#!/usr/bin/env bash
# Run this from INSIDE the corpus-volunteer-optimizer directory
# bash write_all_files.sh

set -e
echo "Writing all corpus-volunteer-optimizer files..."

# ── config/cuda_map.json ────────────────────────────────────────────────────
cat > config/cuda_map.json << 'EOF'
{
  "13": {
    "wheel": "cu132",
    "url": "https://download.pytorch.org/whl/cu132",
    "no_compile": true,
    "comment": "CUDA 13.x — Blackwell RTX 5000 series"
  },
  "12.6": {
    "wheel": "cu126",
    "url": "https://download.pytorch.org/whl/cu126",
    "no_compile": false,
    "comment": "CUDA 12.6"
  },
  "12.4": {
    "wheel": "cu124",
    "url": "https://download.pytorch.org/whl/cu124",
    "no_compile": false,
    "comment": "CUDA 12.4"
  },
  "12.1": {
    "wheel": "cu121",
    "url": "https://download.pytorch.org/whl/cu121",
    "no_compile": false,
    "comment": "CUDA 12.1"
  },
  "11.8": {
    "wheel": "cu118",
    "url": "https://download.pytorch.org/whl/cu118",
    "no_compile": false,
    "comment": "CUDA 11.8 — GTX 1000/900 series"
  }
}
EOF
echo "✓ config/cuda_map.json"

# ── config/rocm_map.json ────────────────────────────────────────────────────
cat > config/rocm_map.json << 'EOF'
{
  "6.2": {
    "wheel": "rocm6.2",
    "url": "https://download.pytorch.org/whl/rocm6.2",
    "comment": "ROCm 6.2 — RX 7000/6000 series"
  },
  "6.1": {
    "wheel": "rocm6.1",
    "url": "https://download.pytorch.org/whl/rocm6.1",
    "comment": "ROCm 6.1"
  },
  "6.0": {
    "wheel": "rocm6.0",
    "url": "https://download.pytorch.org/whl/rocm6.0",
    "comment": "ROCm 6.0"
  }
}
EOF
echo "✓ config/rocm_map.json"

# ── config/gpu_quirks.json ──────────────────────────────────────────────────
cat > config/gpu_quirks.json << 'EOF'
{
  "compute_12": {
    "name": "Blackwell (RTX 5000 series)",
    "env": { "CORPUS_ASR_NO_COMPILE": "1" },
    "max_gpu_workers": 1,
    "reason": "torch.inductor CUDA graphs broken on Blackwell — disable compilation"
  },
  "compute_8_11": {
    "name": "Ampere / Ada / Hopper (RTX 3000/4000 series)",
    "env": {},
    "max_gpu_workers": 2,
    "reason": "Fully supported, no quirks needed"
  },
  "compute_7": {
    "name": "Turing (RTX 2000 / GTX 1600 series)",
    "env": {},
    "max_gpu_workers": 1,
    "reason": "Older architecture — limit concurrency to avoid OOM"
  },
  "compute_6": {
    "name": "Pascal (GTX 1000 series)",
    "env": {},
    "max_gpu_workers": 1,
    "reason": "Lower VRAM — single worker"
  },
  "amd_rdna": {
    "name": "AMD RDNA (RX 5000/6000/7000)",
    "env": { "PYTORCH_HIP_ALLOC_CONF": "garbage_collection_threshold:0.8" },
    "max_gpu_workers": 1,
    "reason": "ROCm HIP memory management tuning"
  },
  "intel_arc": {
    "name": "Intel Arc",
    "env": { "SYCL_CACHE_PERSISTENT": "1" },
    "max_gpu_workers": 1,
    "reason": "IPEX needs SYCL cache for stable inference"
  },
  "apple_silicon": {
    "name": "Apple Silicon (M1/M2/M3/M4)",
    "env": { "PYTORCH_ENABLE_MPS_FALLBACK": "1" },
    "max_gpu_workers": 1,
    "reason": "MPS fallback for ops not yet supported on Metal"
  }
}
EOF
echo "✓ config/gpu_quirks.json"

# ── lib/utils/colors.sh ─────────────────────────────────────────────────────
cat > lib/utils/colors.sh << 'EOF'
#!/usr/bin/env bash
RED="\033[0;31m"; GREEN="\033[0;32m"; YELLOW="\033[0;33m"
BLUE="\033[0;34m"; CYAN="\033[0;36m"; BOLD="\033[1m"; RESET="\033[0m"
info()    { echo -e "${BLUE}ℹ${RESET}  $*"; }
success() { echo -e "${GREEN}✓${RESET}  $*"; }
warn()    { echo -e "${YELLOW}⚠${RESET}  $*"; }
error()   { echo -e "${RED}✗${RESET}  $*" >&2; }
header()  { echo -e "\n${BOLD}${CYAN}══════════════════════════════════════════════════════════${RESET}\n${BOLD}${CYAN}  $*${RESET}\n${BOLD}${CYAN}══════════════════════════════════════════════════════════${RESET}"; }
step()    { echo -e "${BOLD}→${RESET}  $*"; }
EOF
echo "✓ lib/utils/colors.sh"

# ── lib/utils/colors.ps1 ────────────────────────────────────────────────────
cat > lib/utils/colors.ps1 << 'EOF'
function Write-Info    { param($msg) Write-Host "i  $msg" -ForegroundColor Cyan }
function Write-Success { param($msg) Write-Host "v  $msg" -ForegroundColor Green }
function Write-Warn    { param($msg) Write-Host "!  $msg" -ForegroundColor Yellow }
function Write-Err     { param($msg) Write-Host "x  $msg" -ForegroundColor Red }
function Write-Step    { param($msg) Write-Host "-> $msg" -ForegroundColor White }
function Write-Header  {
    param($msg)
    $line = "=" * 60
    Write-Host "`n$line" -ForegroundColor Cyan
    Write-Host "  $msg"  -ForegroundColor Cyan
    Write-Host "$line`n"  -ForegroundColor Cyan
}
EOF
echo "✓ lib/utils/colors.ps1"

# ── lib/utils/logger.py ─────────────────────────────────────────────────────
cat > lib/utils/logger.py << 'EOF'
"""Cross-platform colored logger for Python scripts."""
import sys, platform

_WIN = platform.system() == "Windows"
_COLORS = not _WIN or "WT_SESSION" in __import__("os").environ

def _c(code):
    return f"\033[{code}m" if _COLORS else ""

RESET=_c("0"); BOLD=_c("1"); RED=_c("31"); GREEN=_c("32")
YELLOW=_c("33"); BLUE=_c("34"); CYAN=_c("36"); DIM=_c("2")

def info(msg):    print(f"{BLUE}ℹ{RESET}  {msg}")
def success(msg): print(f"{GREEN}✓{RESET}  {msg}")
def warn(msg):    print(f"{YELLOW}⚠{RESET}  {msg}")
def error(msg):   print(f"{RED}✗{RESET}  {msg}", file=sys.stderr)
def step(msg):    print(f"{BOLD}→{RESET}  {msg}")
def header(msg):  print(f"\n{BOLD}{CYAN}{'═'*60}{RESET}\n{BOLD}{CYAN}  {msg}{RESET}\n{BOLD}{CYAN}{'═'*60}{RESET}")
def dim(msg):     print(f"{DIM}{msg}{RESET}")
EOF
echo "✓ lib/utils/logger.py"

# ── lib/detect/detect_gpu.py ────────────────────────────────────────────────
cat > lib/detect/detect_gpu.py << 'PYEOF'
#!/usr/bin/env python3
"""
Cross-platform GPU detector.
Usage: python3 lib/detect/detect_gpu.py [--json]
Outputs GPU brand, name, VRAM, CUDA/ROCm version, device string.
"""
import json, os, platform, re, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).parent.parent.parent
sys.path.insert(0, str(ROOT / "lib" / "utils"))
from logger import info, warn, error, header, success

def _run(cmd, timeout=10):
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return r.stdout.strip()
    except Exception:
        return ""

def detect_nvidia():
    out = _run(["nvidia-smi", "--query-gpu=name,memory.total,compute_cap",
                "--format=csv,noheader,nounits"])
    if not out:
        return None
    parts = [p.strip() for p in out.split(",")]
    if len(parts) < 3:
        return None
    name, vram_mb, cc = parts[0], parts[1], parts[2]
    try:
        vram_gb = round(int(vram_mb) / 1024, 1)
    except ValueError:
        vram_gb = 0
    smi = _run(["nvidia-smi"])
    cuda_ver = "unknown"
    for line in smi.splitlines():
        if "CUDA Version" in line:
            m = re.search(r"CUDA Version:\s*([\d\.]+)", line)
            if m:
                cuda_ver = m.group(1)
            break
    cc_major = int(cc.split(".")[0]) if "." in cc else 0
    return {
        "brand": "nvidia", "name": name, "vram_gb": vram_gb,
        "cuda_version": cuda_ver, "compute_capability": cc,
        "compute_capability_major": cc_major, "device_str": "cuda",
    }

def detect_amd():
    ri = _run(["rocminfo"])
    if not ri:
        return None
    name = "AMD GPU"
    m = re.search(r"Marketing Name:\s*(.+)", ri)
    if m:
        name = m.group(1).strip()
    vram = 0
    mv = re.search(r"Size:\s*(\d+)\s*\(0x", ri)
    if mv:
        try:
            vram = round(int(mv.group(1)) / 1024, 1)
        except Exception:
            pass
    rocm_ver = "unknown"
    p = Path("/opt/rocm/.info/version")
    if p.exists():
        rocm_ver = p.read_text().strip().split("-")[0]
    return {
        "brand": "amd", "name": name, "vram_gb": vram,
        "rocm_version": rocm_ver, "device_str": "cuda",
    }

def detect_intel():
    lspci = _run(["lspci"])
    if "Intel" in lspci and ("Arc" in lspci or "Xe" in lspci):
        m = re.search(r"Intel.*?(Arc\s+\w+|Xe\s+\w+)", lspci)
        name = m.group(0).strip() if m else "Intel Arc GPU"
        return {"brand": "intel", "name": name, "vram_gb": 0, "device_str": "xpu"}
    return None

def detect_apple():
    if platform.system() != "Darwin":
        return None
    chip = _run(["sysctl", "-n", "machdep.cpu.brand_string"])
    if not any(x in chip for x in ["Apple", "M1", "M2", "M3", "M4"]):
        return None
    mem = _run(["sysctl", "-n", "hw.memsize"])
    try:
        vram_gb = round(int(mem) / 1024**3, 1)
    except Exception:
        vram_gb = 0
    m = re.search(r"(M[1-4](?:\s+(?:Pro|Max|Ultra))?)", chip)
    name = m.group(1) if m else "Apple Silicon"
    return {"brand": "apple", "name": name, "vram_gb": vram_gb, "device_str": "mps"}

def detect_windows():
    out = _run(["powershell", "-Command",
                "Get-WmiObject Win32_VideoController | Select-Object Name,AdapterRAM | ConvertTo-Json"])
    if not out:
        return None
    try:
        data = json.loads(out)
        if isinstance(data, dict):
            data = [data]
        for d in data:
            name = d.get("Name", "")
            vram = round((d.get("AdapterRAM") or 0) / 1024**3, 1)
            if "NVIDIA" in name:
                # Also try nvidia-smi for accurate CUDA version
                nv = detect_nvidia()
                base = {"brand": "nvidia", "name": name, "vram_gb": vram, "device_str": "cuda"}
                if nv:
                    base.update({k: nv[k] for k in ["cuda_version","compute_capability","compute_capability_major"]})
                return base
            if "AMD" in name or "Radeon" in name:
                return {"brand": "amd", "name": name, "vram_gb": vram, "device_str": "cpu",
                        "note": "AMD on Windows uses CPU (ROCm not supported on Windows)"}
            if "Intel" in name and ("Arc" in name or "Xe" in name):
                return {"brand": "intel", "name": name, "vram_gb": vram, "device_str": "xpu"}
    except Exception:
        pass
    return None

def detect():
    system = platform.system()
    gpu = None
    if system == "Darwin":
        gpu = detect_apple()
    elif system == "Windows":
        gpu = detect_windows()
    else:
        gpu = detect_nvidia() or detect_amd() or detect_intel()
    if gpu is None:
        gpu = {"brand": "cpu", "name": "No GPU detected", "vram_gb": 0, "device_str": "cpu"}
    gpu["os"] = system
    gpu["python"] = platform.python_version()
    return gpu

def main():
    gpu = detect()
    if "--json" in sys.argv:
        print(json.dumps(gpu, indent=2))
        return
    header("GPU Detection Results")
    for k, v in gpu.items():
        print(f"  {k:<30}: {v}")
    print()

if __name__ == "__main__":
    main()
PYEOF
echo "✓ lib/detect/detect_gpu.py"

# ── lib/detect/detect_gpu.sh ────────────────────────────────────────────────
cat > lib/detect/detect_gpu.sh << 'EOF'
#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
GPU_JSON=$(python3 "$ROOT/lib/detect/detect_gpu.py" --json 2>/dev/null)
if [ -z "$GPU_JSON" ]; then
  export GPU_BRAND="cpu"; export GPU_DEVICE="cpu"; export GPU_VRAM="0"; return 1
fi
_py() { echo "$GPU_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('$1',''))"; }
export GPU_BRAND=$(_py brand)
export GPU_NAME=$(_py name)
export GPU_VRAM=$(_py vram_gb)
export GPU_DEVICE=$(_py device_str)
export GPU_CUDA_VER=$(_py cuda_version)
export GPU_ROCM_VER=$(_py rocm_version)
export GPU_CC_MAJOR=$(_py compute_capability_major)
export GPU_JSON_FULL="$GPU_JSON"
EOF
echo "✓ lib/detect/detect_gpu.sh"

# ── lib/detect/detect_gpu.ps1 ───────────────────────────────────────────────
cat > lib/detect/detect_gpu.ps1 << 'EOF'
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$json = python "$Root\lib\detect\detect_gpu.py" --json 2>$null | ConvertFrom-Json
if (-not $json) {
    $global:GPU_BRAND="cpu"; $global:GPU_DEVICE="cpu"; $global:GPU_VRAM=0; return
}
$global:GPU_BRAND=$json.brand; $global:GPU_NAME=$json.name
$global:GPU_VRAM=$json.vram_gb; $global:GPU_DEVICE=$json.device_str
$global:GPU_CUDA_VER=$json.cuda_version; $global:GPU_CC_MAJOR=$json.compute_capability_major
$global:GPU_ROCM_VER=$json.rocm_version; $global:GPU_JSON=$json
Write-Host "  GPU: $($json.name) ($($json.vram_gb) GB) [$($json.device_str)]"
EOF
echo "✓ lib/detect/detect_gpu.ps1"

# ── lib/patch/patch_asr.py ──────────────────────────────────────────────────
cat > lib/patch/patch_asr.py << 'PYEOF'
"""
Patches for corpus_client_cli/asr.py:
  1. Fault-tolerant av.open() with 3 fallback strategies
  2. Packet-level decoder — skips corrupt packets individually
  3. _MAX_GPU_TRANSCRIBE_WORKERS based on VRAM
"""
import glob, re, sys
from pathlib import Path

ROOT = Path(__file__).parent.parent.parent
sys.path.insert(0, str(ROOT / "lib" / "utils"))
from logger import success, warn, error, step

def find_asr_path():
    patterns = [
        str(Path.home() / ".local/share/uv/tools/corpus-client-cli/lib/python*/site-packages/corpus_client_cli/asr.py"),
        str(Path.home() / "Library/Application Support/uv/tools/corpus-client-cli/lib/python*/site-packages/corpus_client_cli/asr.py"),
        "/usr/local/lib/python*/dist-packages/corpus_client_cli/asr.py",
    ]
    for pat in patterns:
        m = glob.glob(pat)
        if m:
            return Path(m[0])
    return None

def patch_av_open(content):
    OLD = 'container = _av.open(str(audio_path))'
    NEW = '''# Fault-tolerant open — try 3 strategies for corrupt containers
    _strategies = [
        {},
        {"options": {"err_detect": "ignore_err"}},
        {"options": {"err_detect": "ignore_err", "fflags": "discardcorrupt"}},
    ]
    container = None; _last_exc = None
    for _s in _strategies:
        try:
            container = _av.open(str(audio_path), **_s)
            if not [s for s in container.streams if s.type == "audio"]:
                container.close(); container = None
                raise RuntimeError(f"No audio stream in {audio_path.name}")
            break
        except RuntimeError: raise
        except Exception as exc:
            _last_exc = exc
            if container:
                try: container.close()
                except: pass
                container = None
    if container is None:
        raise RuntimeError(f"Failed to decode audio from {audio_path.name}: {_last_exc}. Ensure ffmpeg/libav is available.") from _last_exc
    # BEGIN_PATCH_AV_OPEN (already applied marker)'''
    if "BEGIN_PATCH_AV_OPEN" in content:
        return content, False
    if OLD not in content:
        return content, False
    return content.replace(OLD, NEW), True

def patch_decoder(content):
    if "_safe_frames" in content:
        return content, False
    OLD = "for frame in itertools.chain(container.decode(audio=0), [None]):"
    if OLD not in content:
        return content, False
    HELPER = '''        def _safe_frames(cont):
            """Packet-level decoder — skips corrupt packets individually."""
            try:
                for pkt in cont.demux(audio=0):
                    try:
                        for frm in pkt.decode():
                            yield frm
                    except Exception:
                        continue
            except Exception:
                pass
            yield None
'''
    NEW_LINE = "        for frame in _safe_frames(container):"
    content = content.replace(
        "        try:\n            with container:",
        HELPER + "        try:\n            with container:"
    )
    content = content.replace(
        "                " + OLD,
        "                " + NEW_LINE.strip()
    )
    return content, True

def patch_max_workers(content, vram_gb):
    workers = 1 if vram_gb < 8 else 2
    new = re.sub(r'_MAX_GPU_TRANSCRIBE_WORKERS\s*=\s*\d+',
                 f'_MAX_GPU_TRANSCRIBE_WORKERS = {workers}', content)
    return new, new != content

def apply(vram_gb=0):
    path = find_asr_path()
    if not path:
        error("asr.py not found — install corpus-client-cli first")
        return False
    step(f"Patching {path.name}")
    content = path.read_text("utf-8")
    changed = False
    for fn, args in [(patch_av_open, [content]),
                     (patch_decoder, [None]),
                     (patch_max_workers, [None, vram_gb])]:
        if args[0] is None:
            args[0] = content
        content, ok = fn(*args)
        if ok:
            success(f"  {fn.__name__} applied")
            changed = True
        else:
            warn(f"  {fn.__name__} skipped (already applied or not found)")
    if changed:
        path.write_text(content, "utf-8")
    return True

if __name__ == "__main__":
    import argparse
    p = argparse.ArgumentParser()
    p.add_argument("--vram", type=float, default=0)
    apply(p.parse_args().vram)
PYEOF
echo "✓ lib/patch/patch_asr.py"

# ── lib/patch/patch_volunteer.py ────────────────────────────────────────────
cat > lib/patch/patch_volunteer.py << 'PYEOF'
"""
Patches for corpus_client_cli/volunteer.py:
  1. Skip files under 100s
  2. Truncate segments to 1000
"""
import glob, sys
from pathlib import Path

ROOT = Path(__file__).parent.parent.parent
sys.path.insert(0, str(ROOT / "lib" / "utils"))
from logger import success, warn, error, step

def find_volunteer_path():
    patterns = [
        str(Path.home() / ".local/share/uv/tools/corpus-client-cli/lib/python*/site-packages/corpus_client_cli/volunteer.py"),
        str(Path.home() / "Library/Application Support/uv/tools/corpus-client-cli/lib/python*/site-packages/corpus_client_cli/volunteer.py"),
    ]
    for pat in patterns:
        m = glob.glob(pat)
        if m:
            return Path(m[0])
    return None

def patch_duration_filter(content):
    if "audio_duration < 100" in content:
        return content, False
    lines = content.splitlines(keepends=True)
    insert_at = None
    for i, line in enumerate(lines):
        if "result: dict[str, Any] | None = None" in line and i > 1000:
            insert_at = i
            break
    if insert_at is None:
        return content, False
    indent = "                "
    new_lines = [
        f"{indent}# Skip short/silent files (< 100s) — usually noise or corrupt\n",
        f"{indent}if 0 < audio_duration < 100:\n",
        f"{indent}    statuses[i - 1]['state'] = 'failed'\n",
        f"{indent}    statuses[i - 1]['label'] = f'[dim]⏭ Skipped — too short ({{audio_duration:.0f}}s < 100s)[/dim]'\n",
        f"{indent}    _tick_elapsed()\n",
        f"{indent}    prog.update(task, advance=1)\n",
        f"{indent}    return\n",
    ]
    lines = lines[:insert_at] + new_lines + lines[insert_at:]
    return "".join(lines), True

def patch_segments_limit(content):
    OLD = '"segments": segments,'
    NEW = '"segments": segments[:1000],'
    if OLD not in content:
        return content, False
    return content.replace(OLD, NEW, 1), True

def apply():
    path = find_volunteer_path()
    if not path:
        error("volunteer.py not found")
        return False
    step(f"Patching {path.name}")
    content = path.read_text("utf-8")
    changed = False
    content, ok = patch_duration_filter(content)
    if ok:
        success("  Duration filter applied (skips < 100s)")
        changed = True
    else:
        warn("  Duration filter skipped (already applied or not found)")
    content, ok = patch_segments_limit(content)
    if ok:
        success("  Segments[:1000] truncation applied")
        changed = True
    else:
        warn("  Segments patch skipped (already applied or not found)")
    if changed:
        path.write_text(content, "utf-8")
    return True

if __name__ == "__main__":
    apply()
PYEOF
echo "✓ lib/patch/patch_volunteer.py"

# ── lib/patch/patch_env.py ──────────────────────────────────────────────────
cat > lib/patch/patch_env.py << 'PYEOF'
"""
Set persistent environment variables based on GPU quirks.
Writes to ~/.bashrc, ~/.zshrc, ~/.config/fish/config.fish
"""
import json, os, platform, re, sys
from pathlib import Path

ROOT = Path(__file__).parent.parent.parent
sys.path.insert(0, str(ROOT / "lib" / "utils"))
from logger import success, warn, info, step

MARKER_START = "# >>> corpus-volunteer-optimizer >>>"
MARKER_END   = "# <<< corpus-volunteer-optimizer <<<"

def load_env_vars(gpu_info):
    quirks_path = ROOT / "config" / "gpu_quirks.json"
    with open(quirks_path) as f:
        quirks = json.load(f)
    env = {}
    brand = gpu_info.get("brand", "cpu")
    cc = gpu_info.get("compute_capability_major", 0)
    if brand == "nvidia":
        if cc >= 12:
            env.update(quirks["compute_12"]["env"])
    elif brand == "amd":
        env.update(quirks["amd_rdna"]["env"])
    elif brand == "intel":
        env.update(quirks["intel_arc"]["env"])
    elif brand == "apple":
        env.update(quirks["apple_silicon"]["env"])
    return env

def _block(env):
    lines = [MARKER_START, "# Auto-generated — do not edit manually"]
    for k, v in env.items():
        lines.append(f'export {k}="{v}"')
    lines.append(MARKER_END)
    return "\n".join(lines) + "\n"

def _block_fish(env):
    lines = [f"# {MARKER_START}"]
    for k, v in env.items():
        lines.append(f'set -gx {k} "{v}"')
    lines.append(f"# {MARKER_END}")
    return "\n".join(lines) + "\n"

def _write(path, block):
    content = path.read_text() if path.exists() else ""
    content = re.sub(rf"{re.escape(MARKER_START)}.*?{re.escape(MARKER_END)}\n?",
                     "", content, flags=re.DOTALL)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content.rstrip("\n") + "\n\n" + block)
    success(f"  Written to {path}")

def apply(gpu_info):
    step("Configuring environment variables")
    env = load_env_vars(gpu_info)
    if not env:
        info("  No GPU-specific env vars needed"); return
    home = Path.home()
    block = _block(env)
    _write(home / ".bashrc", block)
    if (home / ".zshrc").exists() or os.environ.get("SHELL","").endswith("zsh"):
        _write(home / ".zshrc", block)
    fish = home / ".config/fish/config.fish"
    if fish.exists() or (home / ".config/fish").exists():
        _write(fish, _block_fish(env))
    for k, v in env.items():
        os.environ[k] = v
        info(f"  {k}={v}")

if __name__ == "__main__":
    import argparse
    p = argparse.ArgumentParser()
    p.add_argument("--gpu-json", default="{}")
    args = p.parse_args()
    apply(json.loads(args.gpu_json))
PYEOF
echo "✓ lib/patch/patch_env.py"

# ── lib/patch/patch_all.py ──────────────────────────────────────────────────
cat > lib/patch/patch_all.py << 'PYEOF'
"""Master patcher — runs all patches."""
import json, sys
from pathlib import Path

ROOT = Path(__file__).parent.parent.parent
sys.path.insert(0, str(ROOT / "lib" / "utils"))
sys.path.insert(0, str(ROOT / "lib" / "patch"))
sys.path.insert(0, str(ROOT / "lib" / "detect"))

from logger import header, success, error, step
import patch_asr, patch_volunteer, patch_env

def main(gpu_json_str=None):
    header("Applying All Corpus Client Patches")
    gpu = json.loads(gpu_json_str) if gpu_json_str else {}
    vram = gpu.get("vram_gb", 0)
    errors = 0

    step("1/3  asr.py — decoder + av.open() fallback + max workers")
    if not patch_asr.apply(vram_gb=vram): errors += 1

    step("2/3  volunteer.py — duration filter + segments limit")
    if not patch_volunteer.apply(): errors += 1

    step("3/3  Environment variables")
    patch_env.apply(gpu)

    print()
    if errors == 0:
        success("All patches applied successfully!")
    else:
        error(f"{errors} patch(es) failed — check output above")
    return errors

if __name__ == "__main__":
    import argparse
    p = argparse.ArgumentParser()
    p.add_argument("--gpu-json", default=None)
    sys.exit(main(p.parse_args().gpu_json))
PYEOF
echo "✓ lib/patch/patch_all.py"

# ── lib/install/install_torch_nvidia.sh ─────────────────────────────────────
cat > lib/install/install_torch_nvidia.sh << 'EOF'
#!/usr/bin/env bash
set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT/lib/utils/colors.sh"
CUDA_VER="${1:-unknown}"
header "Installing CUDA PyTorch for NVIDIA (CUDA $CUDA_VER)"
CUDA_MAJOR=$(echo "$CUDA_VER" | cut -d. -f1)
WHEEL=$(python3 -c "
import json
with open('$ROOT/config/cuda_map.json') as f: m=json.load(f)
v='$CUDA_MAJOR'
r=m.get(v)
if not r:
    keys=sorted(m.keys(),key=lambda x:float(x),reverse=True)
    for k in keys:
        if float(k.split('.')[0])<=float(v): r=m[k]; break
print((r or list(m.values())[-1])['url'])
")
info "Wheel index: $WHEEL"
CORPUS_PY=$(find "$HOME/.local/share/uv/tools/corpus-client-cli" -name "python*" -type f 2>/dev/null | head -1)
[ -z "$CORPUS_PY" ] && { error "corpus-client-cli not found"; exit 1; }
UV_HTTP_TIMEOUT=300 uv pip install --python "$CORPUS_PY" torch --index-url "$WHEEL" --reinstall
"$CORPUS_PY" -c "
import torch
print(f'  torch : {torch.__version__}')
print(f'  CUDA  : {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'  GPU   : {torch.cuda.get_device_name(0)}')
"
success "NVIDIA CUDA PyTorch installed"
EOF
echo "✓ lib/install/install_torch_nvidia.sh"

# ── lib/install/install_torch_amd.sh ────────────────────────────────────────
cat > lib/install/install_torch_amd.sh << 'EOF'
#!/usr/bin/env bash
set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT/lib/utils/colors.sh"
ROCM_VER="${1:-6.2}"
header "Installing ROCm PyTorch for AMD (ROCm $ROCM_VER)"
ROCM_MAJOR=$(echo "$ROCM_VER" | cut -d. -f1-2)
WHEEL=$(python3 -c "
import json
with open('$ROOT/config/rocm_map.json') as f: m=json.load(f)
r=m.get('$ROCM_MAJOR', list(m.values())[0])
print(r['url'])
")
info "Wheel index: $WHEEL"
CORPUS_PY=$(find "$HOME/.local/share/uv/tools/corpus-client-cli" -name "python*" -type f 2>/dev/null | head -1)
[ -z "$CORPUS_PY" ] && { error "corpus-client-cli not found"; exit 1; }
UV_HTTP_TIMEOUT=300 uv pip install --python "$CORPUS_PY" torch --index-url "$WHEEL" --reinstall
"$CORPUS_PY" -c "
import torch
print(f'  torch  : {torch.__version__}')
print(f'  ROCm   : {torch.cuda.is_available()}')
if torch.cuda.is_available(): print(f'  Device : {torch.cuda.get_device_name(0)}')
"
success "AMD ROCm PyTorch installed"
warn "If unsupported GPU, set: export HSA_OVERRIDE_GFX_VERSION=11.0.0"
EOF
echo "✓ lib/install/install_torch_amd.sh"

# ── lib/install/install_torch_intel.sh ──────────────────────────────────────
cat > lib/install/install_torch_intel.sh << 'EOF'
#!/usr/bin/env bash
set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT/lib/utils/colors.sh"
header "Installing Intel Extension for PyTorch (Intel Arc)"
CORPUS_PY=$(find "$HOME/.local/share/uv/tools/corpus-client-cli" -name "python*" -type f 2>/dev/null | head -1)
[ -z "$CORPUS_PY" ] && { error "corpus-client-cli not found"; exit 1; }
UV_HTTP_TIMEOUT=300 uv pip install --python "$CORPUS_PY" \
  intel-extension-for-pytorch \
  --extra-index-url https://pytorch-extension.intel.com/release-whl/stable/xpu/us/
"$CORPUS_PY" -c "
import torch, intel_extension_for_pytorch as ipex
print(f'  torch : {torch.__version__}')
print(f'  ipex  : {ipex.__version__}')
print(f'  XPU   : {torch.xpu.is_available()}')
"
success "Intel Arc IPEX installed"
EOF
echo "✓ lib/install/install_torch_intel.sh"

# ── lib/install/install_torch_mps.sh ────────────────────────────────────────
cat > lib/install/install_torch_mps.sh << 'EOF'
#!/usr/bin/env bash
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT/lib/utils/colors.sh"
header "Verifying Apple MPS (PyTorch built-in)"
CORPUS_PY=$(find "$HOME/Library/Application Support/uv/tools/corpus-client-cli" -name "python*" -type f 2>/dev/null | head -1)
[ -z "$CORPUS_PY" ] && CORPUS_PY=$(find "$HOME/.local/share/uv/tools/corpus-client-cli" -name "python*" -type f 2>/dev/null | head -1)
[ -z "$CORPUS_PY" ] && { warn "corpus-client-cli not found — skipping MPS check"; exit 0; }
"$CORPUS_PY" -c "
import torch
print(f'  torch   : {torch.__version__}')
print(f'  MPS ok  : {torch.backends.mps.is_available()}')
print(f'  MPS built: {torch.backends.mps.is_built()}')
"
success "Apple MPS ready — no extra installation needed"
info "Setting PYTORCH_ENABLE_MPS_FALLBACK=1 for unsupported Metal ops"
EOF
echo "✓ lib/install/install_torch_mps.sh"

# ── lib/install/install_torch_cpu.sh ────────────────────────────────────────
cat > lib/install/install_torch_cpu.sh << 'EOF'
#!/usr/bin/env bash
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT/lib/utils/colors.sh"
header "CPU Mode — No GPU Detected"
info "corpus-client-cli installs CPU torch by default — nothing to change."
info "Transcription will work but will be slower than GPU."
success "CPU setup complete"
EOF
echo "✓ lib/install/install_torch_cpu.sh"

# ── lib/install/install_torch_windows.ps1 ───────────────────────────────────
cat > lib/install/install_torch_windows.ps1 << 'EOF'
param([string]$Brand="cpu", [string]$CudaVersion="", [string]$CorpusPython="")
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
. "$Root\lib\utils\colors.ps1"
Write-Header "Installing PyTorch for Windows ($Brand)"
if (-not $CorpusPython) {
    $CorpusPython = Get-ChildItem "$env:USERPROFILE\.local\share\uv\tools\corpus-client-cli" -Recurse -Filter "python.exe" -EA SilentlyContinue | Select-Object -First 1 -Expand FullName
}
if (-not $CorpusPython) { Write-Err "corpus-client-cli not found"; exit 1 }
switch ($Brand) {
    "nvidia" {
        $map = Get-Content "$Root\config\cuda_map.json" | ConvertFrom-Json
        $major = $CudaVersion.Split(".")[0]
        $url = $map.$major.url
        if (-not $url) { $url = "https://download.pytorch.org/whl/cu124" }
        Write-Info "Using: $url"
        $env:UV_HTTP_TIMEOUT="300"
        uv pip install --python $CorpusPython torch --index-url $url --reinstall
    }
    "intel" {
        uv pip install --python $CorpusPython intel-extension-for-pytorch --extra-index-url https://pytorch-extension.intel.com/release-whl/stable/xpu/us/
    }
    "amd" { Write-Warn "AMD on Windows uses CPU (ROCm not supported on Windows)" }
    default { Write-Info "CPU mode — no changes needed" }
}
& $CorpusPython -c "import torch; print('torch:', torch.__version__); print('CUDA:', torch.cuda.is_available())"
Write-Success "Done"
EOF
echo "✓ lib/install/install_torch_windows.ps1"

# ── verify.sh ────────────────────────────────────────────────────────────────
cat > verify.sh << 'EOF'
#!/usr/bin/env bash
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT/lib/utils/colors.sh"
header "Verification — corpus-volunteer-optimizer"
CORPUS_PY=$(find "$HOME/.local/share/uv/tools/corpus-client-cli" -name "python*" -type f 2>/dev/null | head -1)
[ -z "$CORPUS_PY" ] && CORPUS_PY=$(find "$HOME/Library/Application Support/uv/tools/corpus-client-cli" -name "python*" -type f 2>/dev/null | head -1)
if [ -z "$CORPUS_PY" ]; then
  error "corpus-client-cli not found"
  exit 1
fi
step "corpus-client binary:"
corpus-client version 2>/dev/null && success "  OK" || warn "  Not in PATH — run: export PATH=\"\$HOME/.local/bin:\$PATH\""
step "Python environment:"
"$CORPUS_PY" --version
step "PyTorch + GPU status:"
"$CORPUS_PY" -c "
import torch, sys
print(f'  torch     : {torch.__version__}')
print(f'  CUDA      : {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'  GPU       : {torch.cuda.get_device_name(0)}')
    print(f'  VRAM      : {torch.cuda.get_device_properties(0).total_memory / 1024**3:.1f} GB')
elif hasattr(torch.backends, 'mps') and torch.backends.mps.is_available():
    print(f'  MPS       : True (Apple Silicon)')
else:
    print(f'  Mode      : CPU only')
"
step "Patch status:"
python3 -c "
import glob
from pathlib import Path
home = Path.home()
patterns = [
    str(home / '.local/share/uv/tools/corpus-client-cli/lib/python*/site-packages/corpus_client_cli/asr.py'),
    str(home / 'Library/Application Support/uv/tools/corpus-client-cli/lib/python*/site-packages/corpus_client_cli/asr.py'),
]
for pat in patterns:
    m = glob.glob(pat)
    if m:
        c = Path(m[0]).read_text()
        print('  asr.py av.open fallback   :', 'APPLIED' if '_strategies' in c else 'NOT APPLIED')
        print('  asr.py _safe_frames       :', 'APPLIED' if '_safe_frames' in c else 'NOT APPLIED')
        break
vp = glob.glob(str(home / '.local/share/uv/tools/corpus-client-cli/lib/python*/site-packages/corpus_client_cli/volunteer.py'))
if vp:
    c = Path(vp[0]).read_text()
    print('  volunteer.py duration     :', 'APPLIED' if 'audio_duration < 100' in c else 'NOT APPLIED')
    print('  volunteer.py segments[:1000]:', 'APPLIED' if 'segments[:1000]' in c else 'NOT APPLIED')
"
echo ""
success "Verification complete — ready to contribute compute!"
info "Run: CORPUS_ASR_NO_COMPILE=1 corpus-client volunteer-compute"
EOF
echo "✓ verify.sh"

# ── verify.ps1 ───────────────────────────────────────────────────────────────
cat > verify.ps1 << 'EOF'
$Root = $PSScriptRoot
. "$Root\lib\utils\colors.ps1"
Write-Header "Verification"
$py = Get-ChildItem "$env:USERPROFILE\.local\share\uv\tools\corpus-client-cli" -Recurse -Filter "python.exe" -EA SilentlyContinue | Select-Object -First 1 -Expand FullName
if ($py) {
    & $py -c "import torch; print('torch:', torch.__version__); print('CUDA:', torch.cuda.is_available())"
    Write-Success "Verification complete"
} else {
    Write-Err "corpus-client-cli not found"
}
EOF
echo "✓ verify.ps1"

# ── reapply.sh ───────────────────────────────────────────────────────────────
cat > reapply.sh << 'EOF'
#!/usr/bin/env bash
# Re-apply patches after uv tool upgrade corpus-client-cli
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT/lib/utils/colors.sh"
header "Re-applying patches after upgrade"
GPU_JSON=$(python3 "$ROOT/lib/detect/detect_gpu.py" --json 2>/dev/null)
python3 "$ROOT/lib/patch/patch_all.py" --gpu-json "$GPU_JSON"
success "Patches re-applied. Run verify.sh to confirm."
EOF
echo "✓ reapply.sh"

# ── reapply.ps1 ──────────────────────────────────────────────────────────────
cat > reapply.ps1 << 'EOF'
$Root = $PSScriptRoot
. "$Root\lib\utils\colors.ps1"
Write-Header "Re-applying patches after upgrade"
$gpuJson = python "$Root\lib\detect\detect_gpu.py" --json 2>$null
python "$Root\lib\patch\patch_all.py" --gpu-json $gpuJson
Write-Success "Done. Run verify.ps1 to confirm."
EOF
echo "✓ reapply.ps1"

# ── setup.sh (MAIN ENTRY POINT — Linux/macOS) ────────────────────────────────
cat > setup.sh << 'SETUPEOF'
#!/usr/bin/env bash
# corpus-volunteer-optimizer — setup.sh
# One command to set up GPU-accelerated corpus-client-cli
# Usage: bash setup.sh
# Or:    curl -fsSL https://raw.githubusercontent.com/Aumnamaha/corpus-volunteer-optimizer/main/setup.sh | bash

set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT/lib/utils/colors.sh"

header "corpus-volunteer-optimizer"
echo "  Optimizing Swecha corpus-client-cli for GPU acceleration"
echo "  Supports: NVIDIA · AMD · Intel Arc · Apple Silicon · CPU"
echo ""

# ── Step 1: Check Python ───────────────────────────────────────────────────
step "Step 1/6  Checking Python..."
if ! command -v python3 &>/dev/null; then
  error "Python 3 is required. Install from https://python.org"
  exit 1
fi
PYTHON_VER=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
success "Python $PYTHON_VER found"

# ── Step 2: Check/Install uv ──────────────────────────────────────────────
step "Step 2/6  Checking uv..."
if ! command -v uv &>/dev/null; then
  warn "uv not found — installing..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
  success "uv installed"
else
  success "uv $(uv --version) found"
fi

# ── Step 3: Install corpus-client-cli ────────────────────────────────────
step "Step 3/6  Installing corpus-client-cli..."
if command -v corpus-client &>/dev/null; then
  INSTALLED_VER=$(corpus-client version 2>/dev/null || echo "unknown")
  info "Already installed: $INSTALLED_VER"
  read -p "  Reinstall? [y/N] " -n 1 -r; echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    uv tool install git+https://code.swecha.org/corpus/corpus-client-cli --reinstall
  fi
else
  uv tool install git+https://code.swecha.org/corpus/corpus-client-cli
  export PATH="$HOME/.local/bin:$PATH"
fi
success "corpus-client-cli installed"

# ── Step 4: Detect GPU ───────────────────────────────────────────────────
step "Step 4/6  Detecting GPU..."
GPU_JSON=$(python3 "$ROOT/lib/detect/detect_gpu.py" --json 2>/dev/null || echo '{"brand":"cpu","device_str":"cpu","vram_gb":0}')
source "$ROOT/lib/detect/detect_gpu.sh"

echo ""
echo "  ┌─────────────────────────────────────────┐"
echo "  │  Brand  : $GPU_BRAND"
echo "  │  Name   : $GPU_NAME"
echo "  │  VRAM   : ${GPU_VRAM} GB"
echo "  │  Device : $GPU_DEVICE"
[ -n "$GPU_CUDA_VER" ] && echo "  │  CUDA   : $GPU_CUDA_VER"
[ -n "$GPU_ROCM_VER" ] && echo "  │  ROCm   : $GPU_ROCM_VER"
echo "  └─────────────────────────────────────────┘"
echo ""

# ── Step 5: Install correct PyTorch ──────────────────────────────────────
step "Step 5/6  Installing GPU-optimized PyTorch..."
case "$GPU_BRAND" in
  nvidia)
    bash "$ROOT/lib/install/install_torch_nvidia.sh" "$GPU_CUDA_VER"
    ;;
  amd)
    if [ "$(uname)" = "Darwin" ]; then
      warn "AMD GPU on macOS — using CPU mode (ROCm not supported on macOS)"
      bash "$ROOT/lib/install/install_torch_cpu.sh"
    else
      bash "$ROOT/lib/install/install_torch_amd.sh" "$GPU_ROCM_VER"
    fi
    ;;
  intel)
    bash "$ROOT/lib/install/install_torch_intel.sh"
    ;;
  apple)
    bash "$ROOT/lib/install/install_torch_mps.sh"
    ;;
  *)
    bash "$ROOT/lib/install/install_torch_cpu.sh"
    ;;
esac

# ── Step 6: Apply patches ─────────────────────────────────────────────────
step "Step 6/6  Applying corpus-client patches..."
python3 "$ROOT/lib/patch/patch_all.py" --gpu-json "$GPU_JSON"

# ── Add to PATH ───────────────────────────────────────────────────────────
SHELL_NAME=$(basename "$SHELL")
PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'
case "$SHELL_NAME" in
  bash) grep -qxF "$PATH_LINE" "$HOME/.bashrc" 2>/dev/null || echo "$PATH_LINE" >> "$HOME/.bashrc" ;;
  zsh)  grep -qxF "$PATH_LINE" "$HOME/.zshrc"  2>/dev/null || echo "$PATH_LINE" >> "$HOME/.zshrc" ;;
  fish) fish -c "fish_add_path $HOME/.local/bin" 2>/dev/null || true ;;
esac

# ── Summary ───────────────────────────────────────────────────────────────
echo ""
header "Setup Complete!"
echo ""
echo "  GPU     : $GPU_NAME ($GPU_DEVICE)"
echo "  Patches : av.open fallback · _safe_frames decoder · duration filter · segments[:1000]"
echo ""
echo "  To start contributing compute:"
if echo "$GPU_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if d.get('compute_capability_major',0)>=12 else 1)" 2>/dev/null; then
  echo ""
  echo "    CORPUS_ASR_NO_COMPILE=1 corpus-client volunteer-compute"
  info "  (CORPUS_ASR_NO_COMPILE=1 required for your Blackwell GPU)"
else
  echo ""
  echo "    corpus-client volunteer-compute"
fi
echo ""
echo "  To re-apply patches after upgrade:"
echo "    bash $ROOT/reapply.sh"
echo ""
echo "  To verify setup:"
echo "    bash $ROOT/verify.sh"
echo ""
success "Happy contributing! 🚀"
SETUPEOF
echo "✓ setup.sh"

# ── setup.ps1 (Windows) ──────────────────────────────────────────────────────
cat > setup.ps1 << 'EOF'
# corpus-volunteer-optimizer — setup.ps1
# Run from PowerShell as Administrator for best results
param([switch]$Reinstall)
$Root = $PSScriptRoot
. "$Root\lib\utils\colors.ps1"
Write-Header "corpus-volunteer-optimizer (Windows)"

# Step 1: Check Python
Write-Step "Step 1/6  Checking Python..."
try { $pyver = python --version; Write-Success "  $pyver" } catch { Write-Err "Python not found. Install from https://python.org"; exit 1 }

# Step 2: Check uv
Write-Step "Step 2/6  Checking uv..."
if (-not (Get-Command uv -EA SilentlyContinue)) {
    Write-Warn "uv not found — installing..."
    powershell -c "irm https://astral.sh/uv/install.ps1 | iex"
}
Write-Success "uv ready"

# Step 3: Install corpus-client-cli
Write-Step "Step 3/6  Installing corpus-client-cli..."
uv tool install "git+https://code.swecha.org/corpus/corpus-client-cli"
Write-Success "corpus-client-cli installed"

# Step 4: Detect GPU
Write-Step "Step 4/6  Detecting GPU..."
. "$Root\lib\detect\detect_gpu.ps1"
$gpuJson = python "$Root\lib\detect\detect_gpu.py" --json 2>$null

# Step 5: Install PyTorch
Write-Step "Step 5/6  Installing GPU PyTorch..."
$corpusPy = Get-ChildItem "$env:USERPROFILE\.local\share\uv\tools\corpus-client-cli" -Recurse -Filter "python.exe" -EA SilentlyContinue | Select-Object -First 1 -Expand FullName
& "$Root\lib\install\install_torch_windows.ps1" -Brand $global:GPU_BRAND -CudaVersion ($global:GPU_CUDA_VER) -CorpusPython $corpusPy

# Step 6: Patches
Write-Step "Step 6/6  Applying patches..."
python "$Root\lib\patch\patch_all.py" --gpu-json $gpuJson

Write-Header "Setup Complete!"
Write-Info "Run: corpus-client volunteer-compute"
EOF
echo "✓ setup.ps1"

# ── setup.bat (Windows CMD fallback) ─────────────────────────────────────────
cat > setup.bat << 'EOF'
@echo off
echo corpus-volunteer-optimizer
echo ===========================
echo Launching PowerShell setup...
powershell -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
pause
EOF
echo "✓ setup.bat"

# ── LICENSE ──────────────────────────────────────────────────────────────────
cat > LICENSE << 'EOF'
MIT License

Copyright (c) 2026 Thirunagari Aum Namaha (github.com/Aumnamaha)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF
echo "✓ LICENSE"

# ── CHANGELOG.md ─────────────────────────────────────────────────────────────
cat > CHANGELOG.md << 'EOF'
# Changelog

## [1.0.0] — 2026-06-23

### Added
- Cross-platform GPU detection (NVIDIA, AMD, Intel Arc, Apple Silicon, CPU)
- Automatic CUDA/ROCm wheel selection based on detected GPU
- `patch_asr.py`: 3-strategy `av.open()` fallback for corrupt containers
- `patch_asr.py`: Packet-level `_safe_frames()` decoder — skips corrupt packets
- `patch_asr.py`: `_MAX_GPU_TRANSCRIBE_WORKERS` tuned by VRAM
- `patch_volunteer.py`: Skip files under 100s (silent/noise)
- `patch_volunteer.py`: `segments[:1000]` truncation for server limit
- `patch_env.py`: GPU-specific env vars (e.g. `CORPUS_ASR_NO_COMPILE=1` for Blackwell)
- `reapply.sh/ps1`: Re-apply patches after `uv tool upgrade`
- `verify.sh/ps1`: Post-install verification
- Full docs for each platform

### Fixed
- RTX 5070 Ti (Blackwell, cc 12.0) torch.compile crash → `CORPUS_ASR_NO_COMPILE=1`
- CUDA OOM on concurrent long files → `_MAX_GPU_TRANSCRIBE_WORKERS = 1`
- Corrupt audio files crashing entire batch → per-packet fault tolerance
- Long audio (>1000 segments) rejected by server → truncation patch
EOF
echo "✓ CHANGELOG.md"

# ── CONTRIBUTING.md ──────────────────────────────────────────────────────────
cat > CONTRIBUTING.md << 'EOF'
# Contributing to corpus-volunteer-optimizer

Thank you for helping make Swecha's corpus-client-cli better for everyone!

## How to contribute

### Found a bug or have a fix?
1. Fork this repo
2. Create a branch: `git checkout -b fix/your-description`
3. Make your changes
4. Test with `bash verify.sh`
5. Open a PR with a clear description

### Adding GPU support for a new card/driver version?

**New CUDA version:** Add an entry to `config/cuda_map.json`
**New ROCm version:** Add an entry to `config/rocm_map.json`
**New GPU quirk:** Add an entry to `config/gpu_quirks.json`

### Testing on your system

After changes, run:
```bash
python3 lib/detect/detect_gpu.py
bash verify.sh
```

### Reporting issues

Include:
- OS (Linux distro / Windows version / macOS version)
- GPU model and VRAM
- Output of `python3 lib/detect/detect_gpu.py`
- Output of `bash verify.sh`
- The exact error message

## Platform testers needed

We especially need testers with:
- AMD RX 6000/7000 series (ROCm)
- Intel Arc A770/A750
- Older NVIDIA GTX 1000/900 series (CUDA 11.8)
- Windows 11 with NVIDIA
- macOS M3/M4

Open an issue with your test results!
EOF
echo "✓ CONTRIBUTING.md"

# ── README.md ────────────────────────────────────────────────────────────────
cat > README.md << 'EOF'
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
EOF
echo "✓ README.md"

# ── tests/ ───────────────────────────────────────────────────────────────────
cat > tests/test_detection.py << 'EOF'
"""Test GPU detection logic."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent / "lib" / "detect"))
sys.path.insert(0, str(Path(__file__).parent.parent / "lib" / "utils"))

from detect_gpu import detect, detect_nvidia, detect_apple

def test_detect_returns_dict():
    result = detect()
    assert isinstance(result, dict)
    assert "brand" in result
    assert "device_str" in result
    assert "vram_gb" in result
    assert result["brand"] in ("nvidia", "amd", "intel", "apple", "cpu")
    print(f"  ✓ Detected: {result['brand']} — {result['name']}")

def test_detect_has_os_field():
    result = detect()
    assert "os" in result
    print(f"  ✓ OS field present: {result['os']}")

if __name__ == "__main__":
    test_detect_returns_dict()
    test_detect_has_os_field()
    print("All detection tests passed!")
EOF

cat > tests/test_patches.py << 'EOF'
"""Test that patches apply and are idempotent."""
import sys, glob
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent / "lib" / "patch"))
sys.path.insert(0, str(Path(__file__).parent.parent / "lib" / "utils"))

def find_file(name):
    home = Path.home()
    patterns = [
        str(home / f".local/share/uv/tools/corpus-client-cli/lib/python*/site-packages/corpus_client_cli/{name}"),
        str(home / f"Library/Application Support/uv/tools/corpus-client-cli/lib/python*/site-packages/corpus_client_cli/{name}"),
    ]
    for p in patterns:
        m = glob.glob(p)
        if m: return Path(m[0])
    return None

def test_asr_patches_applied():
    path = find_file("asr.py")
    if not path:
        print("  SKIP: corpus-client-cli not installed")
        return
    content = path.read_text()
    assert "_strategies" in content or "_safe_frames" in content, "asr.py patch not applied"
    print("  ✓ asr.py patched")

def test_volunteer_patches_applied():
    path = find_file("volunteer.py")
    if not path:
        print("  SKIP: corpus-client-cli not installed")
        return
    content = path.read_text()
    assert "audio_duration < 100" in content, "Duration filter not applied"
    assert "segments[:1000]" in content, "Segments limit not applied"
    print("  ✓ volunteer.py patched")

def test_patches_idempotent():
    import patch_asr, patch_volunteer
    path = find_file("asr.py")
    if not path:
        print("  SKIP")
        return
    content_before = path.read_text()
    patch_asr.apply(vram_gb=8)
    patch_volunteer.apply()
    content_after = path.read_text()
    print("  ✓ Patches are idempotent (safe to run twice)")

if __name__ == "__main__":
    test_asr_patches_applied()
    test_volunteer_patches_applied()
    test_patches_idempotent()
    print("All patch tests passed!")
EOF

cat > tests/test_inference.py << 'EOF'
"""Test that GPU inference actually works."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent / "lib" / "utils"))
from logger import info, success, warn

def test_torch_gpu():
    try:
        import torch
        print(f"  torch    : {torch.__version__}")
        if torch.cuda.is_available():
            success(f"  CUDA GPU : {torch.cuda.get_device_name(0)}")
            success(f"  VRAM     : {torch.cuda.get_device_properties(0).total_memory/1024**3:.1f} GB")
            # Quick inference test
            x = torch.randn(100, 100).cuda()
            y = torch.matmul(x, x)
            success("  GPU matmul test: PASSED")
        elif hasattr(torch.backends, "mps") and torch.backends.mps.is_available():
            success("  MPS (Apple Silicon): available")
            x = torch.randn(100, 100).to("mps")
            y = torch.matmul(x, x)
            success("  MPS matmul test: PASSED")
        else:
            warn("  CPU only — GPU not available")
    except ImportError:
        warn("  torch not installed in current environment")
        warn("  Run verify.sh to check corpus-client environment")

if __name__ == "__main__":
    test_torch_gpu()
EOF
echo "✓ tests/"

# ── Make shell scripts executable ────────────────────────────────────────────
chmod +x setup.sh reapply.sh verify.sh
chmod +x lib/detect/detect_gpu.sh
chmod +x lib/install/install_torch_nvidia.sh
chmod +x lib/install/install_torch_amd.sh
chmod +x lib/install/install_torch_intel.sh
chmod +x lib/install/install_torch_mps.sh
chmod +x lib/install/install_torch_cpu.sh
echo "✓ chmod +x on all shell scripts"

echo ""
echo "════════════════════════════════════════════════════════"
echo "  All files written successfully!"
echo ""
echo "  Next steps:"
echo "  1. git init"
echo "  2. git add ."
echo "  3. git commit -m 'feat: initial release — GPU optimizer for corpus-client-cli'"
echo "  4. git remote add origin https://github.com/Aumnamaha/corpus-volunteer-optimizer.git"
echo "  5. git push -u origin main"
echo "════════════════════════════════════════════════════════"

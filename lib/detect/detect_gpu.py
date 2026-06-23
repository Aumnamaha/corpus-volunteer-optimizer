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

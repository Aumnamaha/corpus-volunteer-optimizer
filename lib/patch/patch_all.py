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

"""
Master patcher -- runs all patches in the correct order.
Called by setup.sh / setup.ps1 after torch installation.

Accepts GPU info either as:
  --gpu-json '<json string>'      (works fine on bash/Linux/macOS)
  --gpu-json-file <path>          (required on Windows -- avoids PowerShell's
                                    native-exe argument quoting bug with JSON
                                    strings that contain embedded double quotes)
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).parent.parent.parent
sys.path.insert(0, str(ROOT / "lib" / "utils"))
sys.path.insert(0, str(ROOT / "lib" / "patch"))
sys.path.insert(0, str(ROOT / "lib" / "detect"))

from logger import header, success, error, info, step
import patch_asr
import patch_volunteer
import patch_env


def main(gpu_json_str: str | None = None, gpu_json_file: str | None = None) -> int:
    header("Applying Corpus Client Patches")

    gpu_info = {}
    raw = None

    if gpu_json_file:
        try:
            # utf-8-sig strips a UTF-8 BOM if present -- PowerShell's
            # "Out-File -Encoding utf8" writes one by default, which breaks
            # plain json.loads() otherwise.
            raw = Path(gpu_json_file).read_text(encoding="utf-8-sig")
        except Exception as e:
            error(f"Could not read --gpu-json-file: {e}")
    elif gpu_json_str:
        raw = gpu_json_str

    if raw:
        try:
            gpu_info = json.loads(raw)
        except Exception as e:
            error(f"Could not parse GPU JSON: {e}")
            error(f"Raw content was: {raw[:200]}")

    vram_gb = gpu_info.get("vram_gb", 0)
    errors = 0

    step("1/3  Patching asr.py")
    if not patch_asr.apply(vram_gb=vram_gb):
        error("asr.py patch failed")
        errors += 1

    step("2/3  Patching volunteer.py")
    if not patch_volunteer.apply():
        error("volunteer.py patch failed")
        errors += 1

    step("3/3  Setting environment variables")
    patch_env.apply(gpu_info)

    if errors == 0:
        success("All patches applied successfully!")
    else:
        error(f"{errors} patch(es) failed -- check output above")

    return errors


if __name__ == "__main__":
    import argparse
    p = argparse.ArgumentParser(description="Apply all corpus-client patches")
    p.add_argument("--gpu-json", type=str, default=None,
                   help="JSON string from detect_gpu.py --json")
    p.add_argument("--gpu-json-file", type=str, default=None,
                   help="Path to a file containing GPU JSON (use on Windows)")
    args = p.parse_args()
    sys.exit(main(args.gpu_json, args.gpu_json_file))

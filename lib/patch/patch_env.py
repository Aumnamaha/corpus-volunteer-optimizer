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

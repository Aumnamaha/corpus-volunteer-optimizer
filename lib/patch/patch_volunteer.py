"""
Patches for corpus_client_cli/volunteer.py
Tested against v0.1.1 and v0.1.2.
Uses multiple fallback patterns for the segments truncation since the
upstream key ordering / quoting changed between versions.

Patches applied:
  1. Skip files under 100s (silent/noise/trash)
  2. Truncate segments to 1000 (server upload limit)
"""
import glob
import sys
from pathlib import Path

ROOT = Path(__file__).parent.parent.parent
sys.path.insert(0, str(ROOT / "lib" / "utils"))
from logger import success, warn, error, step


def find_volunteer_path():
    patterns = [
        str(Path.home() / ".local/share/uv/tools/corpus-client-cli/lib/python*/site-packages/corpus_client_cli/volunteer.py"),
        str(Path.home() / "Library/Application Support/uv/tools/corpus-client-cli/lib/python*/site-packages/corpus_client_cli/volunteer.py"),
        str(Path.home() / "AppData/Roaming/uv/tools/corpus-client-cli/Lib/site-packages/corpus_client_cli/volunteer.py"),
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

    # Primary anchor
    for i, line in enumerate(lines):
        if "result: dict[str, Any] | None = None" in line and i > 1000:
            insert_at = i
            break

    # Fallback anchor -- right after duration is probed / status set to "Transcribing"
    if insert_at is None:
        for i, line in enumerate(lines):
            if "audio_duration = _probe_audio_duration" in line:
                # walk forward to find a safe statement boundary
                for j in range(i + 1, min(i + 15, len(lines))):
                    if lines[j].strip().startswith("result") or lines[j].strip().startswith("try:"):
                        insert_at = j
                        break
                break

    if insert_at is None:
        return content, False

    indent = "                "
    new_lines = [
        f"{indent}# Skip short/silent files (< 100s) -- usually noise or corrupt\n",
        f"{indent}if 0 < audio_duration < 100:\n",
        f"{indent}    statuses[i - 1]['state'] = 'failed'\n",
        f"{indent}    statuses[i - 1]['label'] = f'[dim]Skipped -- too short ({{audio_duration:.0f}}s < 100s)[/dim]'\n",
        f"{indent}    _tick_elapsed()\n",
        f"{indent}    prog.update(task, advance=1)\n",
        f"{indent}    return\n",
    ]
    lines = lines[:insert_at] + new_lines + lines[insert_at:]
    return "".join(lines), True


def patch_segments_limit(content):
    """Try multiple quote/spacing variants for the segments upload field."""
    if "segments[:1000]" in content:
        return content, False

    CANDIDATES = [
        ('"segments": segments,', '"segments": segments[:1000],'),
        ("'segments': segments,", "'segments': segments[:1000],"),
        ('"segments":segments,', '"segments":segments[:1000],'),
        ('"segments": segments ,', '"segments": segments[:1000] ,'),
    ]

    for old, new in CANDIDATES:
        if old in content:
            return content.replace(old, new, 1), True

    return content, False


def verify(path):
    content = path.read_text("utf-8")
    checks = {
        "Duration filter (< 100s)":     "audio_duration < 100" in content,
        "segments[:1000] truncation":   "segments[:1000]" in content,
    }
    for name, applied in checks.items():
        if applied:
            success(f"  {name}")
        else:
            warn(f"  {name} -- NOT APPLIED")


def apply():
    path = find_volunteer_path()
    if not path:
        error("volunteer.py not found -- is corpus-client-cli installed?")
        return False

    step(f"Patching {path.name} ({path})")
    content = path.read_text("utf-8")
    any_changed = False

    content, changed = patch_duration_filter(content)
    if changed:
        success("  Duration filter applied (skips < 100s)")
        any_changed = True
    else:
        warn("  Duration filter -- already applied or pattern not found")

    content, changed = patch_segments_limit(content)
    if changed:
        success("  Segments[:1000] truncation applied")
        any_changed = True
    else:
        warn("  Segments patch -- already applied or pattern not found")

    if any_changed:
        path.write_text(content, "utf-8")
        success(f"  Saved {path.name}")

    verify(path)
    return True


if __name__ == "__main__":
    import argparse
    p = argparse.ArgumentParser()
    p.add_argument("--verify-only", action="store_true")
    args = p.parse_args()

    path = find_volunteer_path()
    if args.verify_only:
        if path:
            verify(path)
        else:
            error("volunteer.py not found")
        import sys as _sys
        _sys.exit(0)

    apply()

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

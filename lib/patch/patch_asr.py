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

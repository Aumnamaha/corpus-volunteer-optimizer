"""
Patches for corpus_client_cli/asr.py
Tested against v0.1.1 and v0.1.2 of corpus-client-cli.
Uses multiple fallback patterns since upstream code structure changes between versions.

Patches applied:
  1. Fault-tolerant av.open() -- 3-strategy fallback for corrupt containers
  2. Packet-level _safe_frames() decoder -- skips corrupt packets individually
  3. _MAX_GPU_TRANSCRIBE_WORKERS -- tuned based on VRAM
"""
import glob
import re
import sys
from pathlib import Path

ROOT = Path(__file__).parent.parent.parent
sys.path.insert(0, str(ROOT / "lib" / "utils"))
from logger import success, warn, error, step


def find_asr_path():
    patterns = [
        # Linux
        str(Path.home() / ".local/share/uv/tools/corpus-client-cli/lib/python*/site-packages/corpus_client_cli/asr.py"),
        # macOS
        str(Path.home() / "Library/Application Support/uv/tools/corpus-client-cli/lib/python*/site-packages/corpus_client_cli/asr.py"),
        # Windows
        str(Path.home() / "AppData/Roaming/uv/tools/corpus-client-cli/Lib/site-packages/corpus_client_cli/asr.py"),
        "/usr/local/lib/python*/dist-packages/corpus_client_cli/asr.py",
    ]
    for pat in patterns:
        m = glob.glob(pat)
        if m:
            return Path(m[0])
    return None


def patch_av_open(content):
    """
    Replace single av.open() call with 3-strategy fallback.
    Tries multiple OLD patterns since quote style / whitespace varies by version.
    """
    if "_open_strategies" in content:
        return content, False

    OLD_A = '''    try:
        container = _av.open(str(audio_path))
        audio_streams = [s for s in container.streams if s.type == "audio"]
        if not audio_streams:
            container.close()
            raise RuntimeError(
                f"No audio stream in {audio_path.name} (file has no audio track)"
            )
    except RuntimeError:
        raise
    except Exception as exc:
        raise RuntimeError(
            f"Failed to decode audio from {audio_path.name}: {exc}. "
            "Ensure ffmpeg/libav is available and the file is a valid audio/video file."
        ) from exc'''

    OLD_B = OLD_A.replace('"', "'")
    OLD_C = "    container = _av.open(str(audio_path))"

    NEW = '''    # PATCH: 3-strategy av.open() fallback for corrupt containers
    _open_strategies = [
        {},
        {"options": {"err_detect": "ignore_err"}},
        {"options": {"err_detect": "ignore_err", "fflags": "discardcorrupt"}},
    ]
    container = None
    _last_exc = None
    for _s in _open_strategies:
        try:
            container = _av.open(str(audio_path), **_s)
            audio_streams = [s for s in container.streams if s.type == "audio"]
            if not audio_streams:
                container.close()
                container = None
                raise RuntimeError(
                    f"No audio stream in {audio_path.name} (file has no audio track)"
                )
            break
        except RuntimeError:
            raise
        except Exception as exc:
            _last_exc = exc
            if container is not None:
                try:
                    container.close()
                except Exception:
                    pass
                container = None
    if container is None:
        raise RuntimeError(
            f"Failed to decode audio from {audio_path.name}: {_last_exc}. "
            "Ensure ffmpeg/libav is available and the file is a valid audio/video file."
        ) from _last_exc'''

    for OLD in (OLD_A, OLD_B, OLD_C):
        if OLD in content:
            return content.replace(OLD, NEW), True

    return content, False


def patch_decoder(content):
    """
    Replace container.decode() iterator with packet-level _safe_frames().
    Skips corrupt packets individually instead of crashing the whole file.
    """
    if "_safe_frames" in content:
        return content, False

    HELPER = '''        def _safe_frames(cont):
            """Packet-level decoder -- skips corrupt packets individually."""
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

    INSERTION_POINTS = [
        "        try:\n            with container:",
        "    try:\n        with container:",
    ]

    insertion_found = None
    for ip in INSERTION_POINTS:
        if ip in content:
            insertion_found = ip
            break

    if insertion_found is None:
        return content, False

    content = content.replace(insertion_found, HELPER + insertion_found)

    DECODE_PATTERNS = [
        (
            "                frames = itertools.chain(container.decode(audio=0), [None])\n"
            "                for frame in frames:",
            "                for frame in _safe_frames(container):",
        ),
        (
            "                for frame in itertools.chain(container.decode(audio=0), [None]):",
            "                for frame in _safe_frames(container):",
        ),
        (
            "            frames = itertools.chain(container.decode(audio=0), [None])\n"
            "            for frame in frames:",
            "            for frame in _safe_frames(container):",
        ),
    ]

    for old, new in DECODE_PATTERNS:
        if old in content:
            content = content.replace(old, new)
            return content, True

    return content, True


def patch_max_workers(content, vram_gb):
    """
    Set _MAX_GPU_TRANSCRIBE_WORKERS based on available VRAM.
    < 8GB VRAM -> 1 worker (prevents CUDA OOM on long files)
    >= 8GB VRAM -> 2 workers (overlaps CPU decode with GPU inference)
    """
    workers = 1 if float(vram_gb) < 8 else 2
    new_content = re.sub(
        r"_MAX_GPU_TRANSCRIBE_WORKERS\s*=\s*\d+",
        f"_MAX_GPU_TRANSCRIBE_WORKERS = {workers}",
        content,
    )
    return new_content, new_content != content


def verify(path):
    """Print patch status for each patch."""
    content = path.read_text("utf-8")
    patches = {
        "av.open() 3-strategy fallback": "_open_strategies" in content,
        "_safe_frames() packet decoder":  "_safe_frames" in content,
        "_MAX_GPU_TRANSCRIBE_WORKERS":    "_MAX_GPU_TRANSCRIBE_WORKERS" in content,
    }
    for name, applied in patches.items():
        if applied:
            success(f"  {name}")
        else:
            warn(f"  {name} -- NOT APPLIED")


def apply(vram_gb=0):
    path = find_asr_path()
    if not path:
        error("asr.py not found -- is corpus-client-cli installed?")
        error("Run: uv tool install git+https://code.swecha.org/corpus/corpus-client-cli")
        return False

    step(f"Patching {path.name} ({path})")
    content = path.read_text("utf-8")
    any_changed = False

    content, changed = patch_av_open(content)
    if changed:
        success("  av.open() 3-strategy fallback -- applied")
        any_changed = True
    else:
        warn("  av.open() patch -- already applied or pattern not found")

    content, changed = patch_decoder(content)
    if changed:
        success("  _safe_frames() packet decoder -- applied")
        any_changed = True
    else:
        warn("  _safe_frames() patch -- already applied or pattern not found")

    content, changed = patch_max_workers(content, vram_gb)
    if changed:
        workers = 1 if float(vram_gb) < 8 else 2
        success(f"  _MAX_GPU_TRANSCRIBE_WORKERS = {workers} (VRAM: {vram_gb}GB)")
        any_changed = True
    else:
        warn("  _MAX_GPU_TRANSCRIBE_WORKERS -- already set or pattern not found")

    if any_changed:
        path.write_text(content, "utf-8")
        success(f"  Saved {path.name}")

    verify(path)
    return True


if __name__ == "__main__":
    import argparse
    p = argparse.ArgumentParser(description="Patch corpus_client_cli/asr.py")
    p.add_argument("--vram", type=float, default=0, help="GPU VRAM in GB")
    p.add_argument("--verify-only", action="store_true", help="Only check patch status")
    args = p.parse_args()

    path = find_asr_path()
    if args.verify_only:
        if path:
            verify(path)
        else:
            error("asr.py not found")
        sys.exit(0)

    apply(args.vram)

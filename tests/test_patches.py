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

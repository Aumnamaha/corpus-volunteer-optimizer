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

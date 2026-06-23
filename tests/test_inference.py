"""Test that GPU inference actually works."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent / "lib" / "utils"))
from logger import info, success, warn

def test_torch_gpu():
    try:
        import torch
        print(f"  torch    : {torch.__version__}")
        if torch.cuda.is_available():
            success(f"  CUDA GPU : {torch.cuda.get_device_name(0)}")
            success(f"  VRAM     : {torch.cuda.get_device_properties(0).total_memory/1024**3:.1f} GB")
            # Quick inference test
            x = torch.randn(100, 100).cuda()
            y = torch.matmul(x, x)
            success("  GPU matmul test: PASSED")
        elif hasattr(torch.backends, "mps") and torch.backends.mps.is_available():
            success("  MPS (Apple Silicon): available")
            x = torch.randn(100, 100).to("mps")
            y = torch.matmul(x, x)
            success("  MPS matmul test: PASSED")
        else:
            warn("  CPU only — GPU not available")
    except ImportError:
        warn("  torch not installed in current environment")
        warn("  Run verify.sh to check corpus-client environment")

if __name__ == "__main__":
    test_torch_gpu()

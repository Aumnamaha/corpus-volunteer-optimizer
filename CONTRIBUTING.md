# Contributing to corpus-volunteer-optimizer

Thank you for helping make Swecha's corpus-client-cli better for everyone!

## How to contribute

### Found a bug or have a fix?
1. Fork this repo
2. Create a branch: `git checkout -b fix/your-description`
3. Make your changes
4. Test with `bash verify.sh`
5. Open a PR with a clear description

### Adding GPU support for a new card/driver version?

**New CUDA version:** Add an entry to `config/cuda_map.json`
**New ROCm version:** Add an entry to `config/rocm_map.json`
**New GPU quirk:** Add an entry to `config/gpu_quirks.json`

### Testing on your system

After changes, run:
```bash
python3 lib/detect/detect_gpu.py
bash verify.sh
```

### Reporting issues

Include:
- OS (Linux distro / Windows version / macOS version)
- GPU model and VRAM
- Output of `python3 lib/detect/detect_gpu.py`
- Output of `bash verify.sh`
- The exact error message

## Platform testers needed

We especially need testers with:
- AMD RX 6000/7000 series (ROCm)
- Intel Arc A770/A750
- Older NVIDIA GTX 1000/900 series (CUDA 11.8)
- Windows 11 with NVIDIA
- macOS M3/M4

Open an issue with your test results!

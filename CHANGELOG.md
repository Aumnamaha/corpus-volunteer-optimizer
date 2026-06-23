# Changelog

## [1.0.0] — 2026-06-23

### Added
- Cross-platform GPU detection (NVIDIA, AMD, Intel Arc, Apple Silicon, CPU)
- Automatic CUDA/ROCm wheel selection based on detected GPU
- `patch_asr.py`: 3-strategy `av.open()` fallback for corrupt containers
- `patch_asr.py`: Packet-level `_safe_frames()` decoder — skips corrupt packets
- `patch_asr.py`: `_MAX_GPU_TRANSCRIBE_WORKERS` tuned by VRAM
- `patch_volunteer.py`: Skip files under 100s (silent/noise)
- `patch_volunteer.py`: `segments[:1000]` truncation for server limit
- `patch_env.py`: GPU-specific env vars (e.g. `CORPUS_ASR_NO_COMPILE=1` for Blackwell)
- `reapply.sh/ps1`: Re-apply patches after `uv tool upgrade`
- `verify.sh/ps1`: Post-install verification
- Full docs for each platform

### Fixed
- RTX 5070 Ti (Blackwell, cc 12.0) torch.compile crash → `CORPUS_ASR_NO_COMPILE=1`
- CUDA OOM on concurrent long files → `_MAX_GPU_TRANSCRIBE_WORKERS = 1`
- Corrupt audio files crashing entire batch → per-packet fault tolerance
- Long audio (>1000 segments) rejected by server → truncation patch

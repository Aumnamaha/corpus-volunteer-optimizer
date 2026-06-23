#!/usr/bin/env bash
# corpus-volunteer-optimizer — setup.sh
# One command to set up GPU-accelerated corpus-client-cli
# Usage: bash setup.sh
# Or:    curl -fsSL https://raw.githubusercontent.com/Aumnamaha/corpus-volunteer-optimizer/main/setup.sh | bash

set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT/lib/utils/colors.sh"

header "corpus-volunteer-optimizer"
echo "  Optimizing Swecha corpus-client-cli for GPU acceleration"
echo "  Supports: NVIDIA · AMD · Intel Arc · Apple Silicon · CPU"
echo ""

# ── Step 1: Check Python ───────────────────────────────────────────────────
step "Step 1/6  Checking Python..."
if ! command -v python3 &>/dev/null; then
  error "Python 3 is required. Install from https://python.org"
  exit 1
fi
PYTHON_VER=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
success "Python $PYTHON_VER found"

# ── Step 2: Check/Install uv ──────────────────────────────────────────────
step "Step 2/6  Checking uv..."
if ! command -v uv &>/dev/null; then
  warn "uv not found — installing..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
  success "uv installed"
else
  success "uv $(uv --version) found"
fi

# ── Step 3: Install corpus-client-cli ────────────────────────────────────
step "Step 3/6  Installing corpus-client-cli..."
if command -v corpus-client &>/dev/null; then
  INSTALLED_VER=$(corpus-client version 2>/dev/null || echo "unknown")
  info "Already installed: $INSTALLED_VER"
  read -p "  Reinstall? [y/N] " -n 1 -r; echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    uv tool install git+https://code.swecha.org/corpus/corpus-client-cli --reinstall
  fi
else
  uv tool install git+https://code.swecha.org/corpus/corpus-client-cli
  export PATH="$HOME/.local/bin:$PATH"
fi
success "corpus-client-cli installed"

# ── Step 4: Detect GPU ───────────────────────────────────────────────────
step "Step 4/6  Detecting GPU..."
GPU_JSON=$(python3 "$ROOT/lib/detect/detect_gpu.py" --json 2>/dev/null || echo '{"brand":"cpu","device_str":"cpu","vram_gb":0}')
source "$ROOT/lib/detect/detect_gpu.sh"

echo ""
echo "  ┌─────────────────────────────────────────┐"
echo "  │  Brand  : $GPU_BRAND"
echo "  │  Name   : $GPU_NAME"
echo "  │  VRAM   : ${GPU_VRAM} GB"
echo "  │  Device : $GPU_DEVICE"
[ -n "$GPU_CUDA_VER" ] && echo "  │  CUDA   : $GPU_CUDA_VER"
[ -n "$GPU_ROCM_VER" ] && echo "  │  ROCm   : $GPU_ROCM_VER"
echo "  └─────────────────────────────────────────┘"
echo ""

# ── Step 5: Install correct PyTorch ──────────────────────────────────────
step "Step 5/6  Installing GPU-optimized PyTorch..."
case "$GPU_BRAND" in
  nvidia)
    bash "$ROOT/lib/install/install_torch_nvidia.sh" "$GPU_CUDA_VER"
    ;;
  amd)
    if [ "$(uname)" = "Darwin" ]; then
      warn "AMD GPU on macOS — using CPU mode (ROCm not supported on macOS)"
      bash "$ROOT/lib/install/install_torch_cpu.sh"
    else
      bash "$ROOT/lib/install/install_torch_amd.sh" "$GPU_ROCM_VER"
    fi
    ;;
  intel)
    bash "$ROOT/lib/install/install_torch_intel.sh"
    ;;
  apple)
    bash "$ROOT/lib/install/install_torch_mps.sh"
    ;;
  *)
    bash "$ROOT/lib/install/install_torch_cpu.sh"
    ;;
esac

# ── Step 6: Apply patches ─────────────────────────────────────────────────
step "Step 6/6  Applying corpus-client patches..."
python3 "$ROOT/lib/patch/patch_all.py" --gpu-json "$GPU_JSON"

# ── Add to PATH ───────────────────────────────────────────────────────────
SHELL_NAME=$(basename "$SHELL")
PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'
case "$SHELL_NAME" in
  bash) grep -qxF "$PATH_LINE" "$HOME/.bashrc" 2>/dev/null || echo "$PATH_LINE" >> "$HOME/.bashrc" ;;
  zsh)  grep -qxF "$PATH_LINE" "$HOME/.zshrc"  2>/dev/null || echo "$PATH_LINE" >> "$HOME/.zshrc" ;;
  fish) fish -c "fish_add_path $HOME/.local/bin" 2>/dev/null || true ;;
esac

# ── Summary ───────────────────────────────────────────────────────────────
echo ""
header "Setup Complete!"
echo ""
echo "  GPU     : $GPU_NAME ($GPU_DEVICE)"
echo "  Patches : av.open fallback · _safe_frames decoder · duration filter · segments[:1000]"
echo ""
echo "  To start contributing compute:"
if echo "$GPU_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if d.get('compute_capability_major',0)>=12 else 1)" 2>/dev/null; then
  echo ""
  echo "    CORPUS_ASR_NO_COMPILE=1 corpus-client volunteer-compute"
  info "  (CORPUS_ASR_NO_COMPILE=1 required for your Blackwell GPU)"
else
  echo ""
  echo "    corpus-client volunteer-compute"
fi
echo ""
echo "  To re-apply patches after upgrade:"
echo "    bash $ROOT/reapply.sh"
echo ""
echo "  To verify setup:"
echo "    bash $ROOT/verify.sh"
echo ""
success "Happy contributing! 🚀"

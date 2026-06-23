#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════╗
# ║          corpus-volunteer-optimizer — setup.sh                          ║
# ║          One command GPU setup for Swecha corpus-client-cli             ║
# ║          github.com/Aumnamaha/corpus-volunteer-optimizer                ║
# ╚══════════════════════════════════════════════════════════════════════════╝
#
# Usage:
#   bash setup.sh
#
# One-liner install:
#   curl -fsSL https://raw.githubusercontent.com/Aumnamaha/corpus-volunteer-optimizer/main/setup.sh | bash

set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# If sourced via curl | bash, ROOT will be wrong — handle that
if [ ! -f "$ROOT/lib/utils/colors.sh" ]; then
  echo "⚠  Running via curl — cloning repo first..."
  git clone https://github.com/Aumnamaha/corpus-volunteer-optimizer.git /tmp/corpus-optimizer
  ROOT="/tmp/corpus-optimizer"
  cd "$ROOT"
fi

source "$ROOT/lib/utils/colors.sh"

header "corpus-volunteer-optimizer"
echo "  GPU acceleration setup for Swecha corpus-client volunteer compute"
echo "  Supports: NVIDIA · AMD · Intel Arc · Apple Silicon · CPU"
echo "  github.com/Aumnamaha/corpus-volunteer-optimizer"
echo ""

# ── Step 1: Check Python ───────────────────────────────────────────────────
step "Step 1/7  Checking Python..."
if ! command -v python3 &>/dev/null; then
  error "Python 3.14+ is required."
  echo "       Install from: https://python.org"
  exit 1
fi
PYTHON_VER=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
PYTHON_MAJOR=$(python3 -c "import sys; print(sys.version_info.major)")
PYTHON_MINOR=$(python3 -c "import sys; print(sys.version_info.minor)")
if [ "$PYTHON_MAJOR" -lt 3 ] || { [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 11 ]; }; then
  error "Python 3.11+ required (corpus-client-cli needs 3.14+, but 3.11 works for our scripts)"
  error "Your version: $PYTHON_VER"
  exit 1
fi
success "Python $PYTHON_VER found"

# ── Step 2: Check/Install uv ──────────────────────────────────────────────
step "Step 2/7  Checking uv..."
if ! command -v uv &>/dev/null; then
  warn "uv not found — installing..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  # Add uv to PATH for this session
  export PATH="$HOME/.local/bin:$PATH"
  if ! command -v uv &>/dev/null; then
    export PATH="$HOME/.cargo/bin:$PATH"
  fi
  success "uv installed"
else
  success "uv $(uv --version) found"
fi

# ── Step 3: Install corpus-client-cli ────────────────────────────────────
step "Step 3/7  Installing corpus-client-cli..."

# Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"

ALREADY_INSTALLED=false
if command -v corpus-client &>/dev/null; then
  CURRENT_VER=$(corpus-client --skip-update version 2>/dev/null || echo "unknown")
  info "Already installed: corpus-client $CURRENT_VER"
  ALREADY_INSTALLED=true
  read -p "  Reinstall/upgrade? [y/N] " -n 1 -r; echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    ALREADY_INSTALLED=false
  fi
fi

if [ "$ALREADY_INSTALLED" = false ]; then
  info "Trying official Swecha PyPI registry..."
  if uv tool install \
    --index "https://code.swecha.org/api/v4/projects/corpus%2Fcorpus-client-cli/packages/pypi/simple" \
    corpus-client-cli 2>/dev/null; then
    success "Installed from Swecha PyPI registry"
  else
    warn "Registry install failed — falling back to git..."
    uv tool install git+https://code.swecha.org/corpus/corpus-client-cli
    success "Installed from git repository"
  fi
fi

# Verify install
if ! command -v corpus-client &>/dev/null; then
  warn "corpus-client not in PATH — adding ~/.local/bin to PATH"
  export PATH="$HOME/.local/bin:$PATH"
fi
INSTALLED_VER=$(corpus-client --skip-update version 2>/dev/null || echo "unknown")
success "corpus-client $INSTALLED_VER ready"

# ── IMPORTANT: Disable auto-update to protect our patches ─────────────────
# corpus-client auto-updates itself on every run (unless --skip-update is used)
# This would wipe our patches silently. We handle this by:
# 1. Always using --skip-update in our recommended run command
# 2. Providing reapply.sh for after manual upgrades
info "Note: corpus-client auto-updates on each run — use --skip-update to protect patches"

# ── Step 4: Detect GPU ───────────────────────────────────────────────────
step "Step 4/7  Detecting GPU..."
GPU_JSON=$(python3 "$ROOT/lib/detect/detect_gpu.py" --json 2>/dev/null \
  || echo '{"brand":"cpu","device_str":"cpu","vram_gb":0,"name":"No GPU","os":"Linux"}')

source "$ROOT/lib/detect/detect_gpu.sh" 2>/dev/null || true

# Parse GPU info from JSON
GPU_BRAND=$(echo "$GPU_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('brand','cpu'))")
GPU_NAME=$(echo "$GPU_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('name','Unknown'))")
GPU_VRAM=$(echo "$GPU_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('vram_gb',0))")
GPU_DEVICE=$(echo "$GPU_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('device_str','cpu'))")
GPU_CUDA_VER=$(echo "$GPU_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('cuda_version',''))" 2>/dev/null || echo "")
GPU_ROCM_VER=$(echo "$GPU_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('rocm_version',''))" 2>/dev/null || echo "")
GPU_CC_MAJOR=$(echo "$GPU_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('compute_capability_major',0))" 2>/dev/null || echo "0")

echo ""
echo "  ┌──────────────────────────────────────────────┐"
printf "  │  %-10s : %-32s│\n" "Brand"  "$GPU_BRAND"
printf "  │  %-10s : %-32s│\n" "GPU"    "$GPU_NAME"
printf "  │  %-10s : %-32s│\n" "VRAM"   "${GPU_VRAM} GB"
printf "  │  %-10s : %-32s│\n" "Device" "$GPU_DEVICE"
[ -n "$GPU_CUDA_VER" ] && printf "  │  %-10s : %-32s│\n" "CUDA"   "$GPU_CUDA_VER"
[ -n "$GPU_ROCM_VER" ] && printf "  │  %-10s : %-32s│\n" "ROCm"   "$GPU_ROCM_VER"
echo "  └──────────────────────────────────────────────┘"
echo ""

# ── Step 5: Install correct PyTorch ──────────────────────────────────────
step "Step 5/7  Installing GPU-optimized PyTorch..."

case "$GPU_BRAND" in
  nvidia)
    bash "$ROOT/lib/install/install_torch_nvidia.sh" "$GPU_CUDA_VER"
    ;;
  amd)
    OS_NAME="$(uname)"
    if [ "$OS_NAME" = "Darwin" ]; then
      warn "AMD GPU on macOS — ROCm not supported on macOS, using CPU mode"
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

# ── Step 6: Apply corpus-client patches ──────────────────────────────────
step "Step 6/7  Applying corpus-client patches..."
python3 "$ROOT/lib/patch/patch_all.py" --gpu-json "$GPU_JSON"

# ── Step 7: Configure shell environment ──────────────────────────────────
step "Step 7/7  Configuring shell environment..."

# Detect shell and config file
SHELL_NAME=$(basename "${SHELL:-bash}")
case "$SHELL_NAME" in
  fish)
    SHELL_RC="$HOME/.config/fish/config.fish"
    PATH_CMD="fish_add_path $HOME/.local/bin"
    ;;
  zsh)
    SHELL_RC="$HOME/.zshrc"
    PATH_CMD='export PATH="$HOME/.local/bin:$PATH"'
    ;;
  *)
    SHELL_RC="$HOME/.bashrc"
    PATH_CMD='export PATH="$HOME/.local/bin:$PATH"'
    ;;
esac

# Add PATH if not already there
if [ -f "$SHELL_RC" ] && grep -q ".local/bin" "$SHELL_RC" 2>/dev/null; then
  info "  PATH already configured in $SHELL_RC"
else
  echo "$PATH_CMD" >> "$SHELL_RC"
  success "  Added ~/.local/bin to PATH in $SHELL_RC"
fi

# Determine run command based on GPU
NEEDS_NO_COMPILE=false
if [ "$GPU_BRAND" = "nvidia" ] && [ "$GPU_CC_MAJOR" -ge 12 ] 2>/dev/null; then
  NEEDS_NO_COMPILE=true
fi

if [ "$NEEDS_NO_COMPILE" = true ]; then
  RUN_CMD="CORPUS_ASR_NO_COMPILE=1 corpus-client --skip-update volunteer-compute"
else
  RUN_CMD="corpus-client --skip-update volunteer-compute"
fi

# ── Final Summary ─────────────────────────────────────────────────────────
echo ""
header "Setup Complete! 🚀"
echo ""
echo "  GPU       : $GPU_NAME"
echo "  Backend   : $GPU_DEVICE"
echo "  Patches   :"
echo "            · av.open() 3-strategy fallback (corrupt containers)"
echo "            · _safe_frames() packet-level decoder (corrupt packets)"
echo "            · Duration filter (skips files < 100s)"
echo "            · segments[:1000] truncation (server upload limit)"
[ "$NEEDS_NO_COMPILE" = true ] && echo "            · CORPUS_ASR_NO_COMPILE=1 (Blackwell GPU fix)"
echo ""
echo "  ┌─────────────────────────────────────────────────────────┐"
echo "  │  To start contributing compute:                         │"
echo "  │                                                         │"
echo "  │    $RUN_CMD"
echo "  │                                                         │"
echo "  │  ⚠  Use --skip-update to protect patches from          │"
echo "  │     corpus-client's auto-update system                  │"
echo "  └─────────────────────────────────────────────────────────┘"
echo ""
echo "  Other useful commands:"
echo ""
echo "    corpus-client --skip-update login          # login to corpus API"
echo "    corpus-client --skip-update profile        # check your compute hours"
echo "    bash $ROOT/verify.sh                       # verify GPU setup"
echo "    bash $ROOT/reapply.sh                      # re-apply patches after upgrade"
echo ""
warn "If corpus-client auto-updates and patches break, run: bash $ROOT/reapply.sh"
echo ""
success "Happy contributing to Swecha's Indic AI corpus! 🇮🇳"
#!/usr/bin/env bash
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT/lib/utils/colors.sh"
header "CPU Mode — No GPU Detected"
info "corpus-client-cli installs CPU torch by default — nothing to change."
info "Transcription will work but will be slower than GPU."
success "CPU setup complete"

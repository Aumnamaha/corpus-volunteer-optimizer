#!/usr/bin/env bash
# run_forever.sh -- keeps corpus-client volunteer-compute running continuously.
# --always only clears ONE batch (usually 20 records) then exits.
# This wraps it in a loop so it restarts automatically until you Ctrl+C.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT/lib/utils/colors.sh" 2>/dev/null || true

echo "Starting continuous volunteer-compute loop."
echo "Press Ctrl+C to stop at any time -- your progress is saved after each batch."
echo ""

trap 'echo ""; echo "Stopped. Thanks for contributing!"; exit 0' INT

BATCH=1
while true; do
  echo "─────────────────────────────────────────"
  echo "  Batch #$BATCH"
  echo "─────────────────────────────────────────"
  corpus-client volunteer-compute --always
  echo ""
  echo "Batch #$BATCH complete -- restarting in 10s (Ctrl+C to stop)..."
  sleep 10
  BATCH=$((BATCH + 1))
done

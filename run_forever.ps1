# run_forever.ps1 -- keeps corpus-client volunteer-compute running continuously.
# --always only clears ONE batch then exits. This loops it until Ctrl+C.

Write-Host "Starting continuous volunteer-compute loop."
Write-Host "Press Ctrl+C to stop at any time -- your progress is saved after each batch."
Write-Host ""

$batch = 1
while ($true) {
    Write-Host "-----------------------------------------"
    Write-Host "  Batch #$batch"
    Write-Host "-----------------------------------------"
    corpus-client volunteer-compute --always
    Write-Host ""
    Write-Host "Batch #$batch complete -- restarting in 10s (Ctrl+C to stop)..."
    Start-Sleep -Seconds 10
    $batch++
}

# run_forever.ps1 -- keeps corpus-client volunteer-compute running continuously.
# --always only clears ONE batch then exits. This loops it until Ctrl+C.

# Always set CORPUS_ASR_NO_COMPILE for this session -- protects against Triton/
# torch.compile crashes on newer NVIDIA GPUs (Blackwell) even if the persistent
# registry value hasn't taken effect yet in this terminal window.
if (-not $env:CORPUS_ASR_NO_COMPILE) {
    $regValue = [System.Environment]::GetEnvironmentVariable("CORPUS_ASR_NO_COMPILE", "User")
    if ($regValue) {
        $env:CORPUS_ASR_NO_COMPILE = $regValue
        Write-Host "Loaded CORPUS_ASR_NO_COMPILE=$regValue from saved settings for this session."
    }
}

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

# verify.ps1 -- post-install verification for corpus-volunteer-optimizer
$Root = $PSScriptRoot
. "$Root\lib\utils\colors.ps1"
Write-Header "Verification -- corpus-volunteer-optimizer"

# uv on Windows installs tools under AppData\Roaming, NOT .local -- check both
$CorpusPy = Get-ChildItem "$env:APPDATA\uv\tools\corpus-client-cli" -Recurse -Filter "python.exe" -ErrorAction SilentlyContinue |
    Select-Object -First 1 -ExpandProperty FullName

if (-not $CorpusPy) {
    $CorpusPy = Get-ChildItem "$env:USERPROFILE\.local\share\uv\tools\corpus-client-cli" -Recurse -Filter "python.exe" -ErrorAction SilentlyContinue |
        Select-Object -First 1 -ExpandProperty FullName
}

Write-Step "corpus-client binary:"
if (Get-Command corpus-client -ErrorAction SilentlyContinue) {
    $ver = corpus-client version 2>$null
    Write-Success "  $ver"
} else {
    Write-Warn "  Not in PATH -- run: `$env:PATH = `"`$env:USERPROFILE\.local\bin;`$env:PATH`""
}

Write-Step "Python environment:"
if ($CorpusPy) {
    & $CorpusPy --version
    Write-Success "  OK ($CorpusPy)"
} else {
    Write-Err "  corpus-client-cli Python not found in AppData\Roaming or .local"
}

Write-Step "PyTorch + GPU status:"
if ($CorpusPy) {
    & $CorpusPy -c "
import torch
print(f'  torch     : {torch.__version__}')
print(f'  CUDA      : {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'  GPU       : {torch.cuda.get_device_name(0)}')
    print(f'  VRAM      : {torch.cuda.get_device_properties(0).total_memory / 1024**3:.1f} GB')
else:
    print(f'  Mode      : CPU only')
"
} else {
    Write-Warn "  Skipping -- Python not found"
}

Write-Step "Patch status:"
if ($CorpusPy) {
    $siteDir = Split-Path (Split-Path $CorpusPy -Parent) -Parent
    $asrPath = Join-Path $siteDir "Lib\site-packages\corpus_client_cli\asr.py"
    $volPath = Join-Path $siteDir "Lib\site-packages\corpus_client_cli\volunteer.py"

    if (Test-Path $asrPath) {
        $asrContent = Get-Content $asrPath -Raw
        $avOpen = if ($asrContent -match "_open_strategies") { "APPLIED" } else { "NOT APPLIED" }
        $safeFrames = if ($asrContent -match "_safe_frames") { "APPLIED" } else { "NOT APPLIED" }
        Write-Host "  asr.py av.open fallback    : $avOpen"
        Write-Host "  asr.py _safe_frames        : $safeFrames"
    } else {
        Write-Warn "  asr.py not found at $asrPath"
    }

    if (Test-Path $volPath) {
        $volContent = Get-Content $volPath -Raw
        $duration = if ($volContent -match "audio_duration < 100") { "APPLIED" } else { "NOT APPLIED" }
        $segments = if ($volContent -match "segments\[:1000\]") { "APPLIED" } else { "NOT APPLIED" }
        Write-Host "  volunteer.py duration      : $duration"
        Write-Host "  volunteer.py segments[:1000]: $segments"
    } else {
        Write-Warn "  volunteer.py not found at $volPath"
    }
}

Write-Host ""
Write-Success "Verification complete!"
Write-Info "Run once:      corpus-client volunteer-compute --always"
Write-Info "Run forever:   .\run_forever.ps1"

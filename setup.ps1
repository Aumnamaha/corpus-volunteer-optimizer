# corpus-volunteer-optimizer -- setup.ps1
# One command GPU setup for Swecha corpus-client-cli on Windows
# Usage: .\setup.ps1

$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot
. "$Root\lib\utils\colors.ps1"

Write-Header "corpus-volunteer-optimizer"
Write-Host "  GPU acceleration setup for Swecha corpus-client volunteer compute"
Write-Host "  Supports: NVIDIA - AMD - Intel Arc - CPU"
Write-Host "  github.com/Aumnamaha/corpus-volunteer-optimizer"
Write-Host ""

# --- Step 1: Check Python -------------------------------------------------
Write-Step "Step 1/7  Checking Python..."
try {
    $pyver = python --version 2>&1
    Write-Success "  $pyver found"
} catch {
    Write-Err "Python not found. Install from https://python.org or run:"
    Write-Err "  winget install --id Python.Python.3.12 -e --source winget"
    exit 1
}

# --- Step 2: Check / Install uv --------------------------------------------
Write-Step "Step 2/7  Checking uv..."
if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
    Write-Warn "uv not found -- installing..."
    powershell -ExecutionPolicy Bypass -Command "irm https://astral.sh/uv/install.ps1 | iex"
    $env:Path = "$env:USERPROFILE\.local\bin;$env:Path"
}
$uvver = uv --version
Write-Success "  $uvver found"

# --- Step 3: Install corpus-client-cli -------------------------------------
Write-Step "Step 3/7  Installing corpus-client-cli..."

$alreadyInstalled = $false
if (Get-Command corpus-client -ErrorAction SilentlyContinue) {
    $installedVer = corpus-client version 2>$null
    Write-Info "  Already installed: $installedVer"
    $alreadyInstalled = $true
    $reply = Read-Host "  Reinstall/upgrade? [y/N]"
    if ($reply -eq "y" -or $reply -eq "Y") {
        $alreadyInstalled = $false
    }
}

if (-not $alreadyInstalled) {
    Write-Info "  Trying official Swecha PyPI registry..."
    $registryOk = $true
    try {
        uv tool install --index "https://code.swecha.org/api/v4/projects/corpus%2Fcorpus-client-cli/packages/pypi/simple" corpus-client-cli 2>$null
        if ($LASTEXITCODE -ne 0) { $registryOk = $false }
    } catch {
        $registryOk = $false
    }
    if (-not $registryOk) {
        Write-Warn "  Registry install failed -- falling back to git..."
        uv tool install "git+https://code.swecha.org/corpus/corpus-client-cli"
    } else {
        Write-Success "  Installed from Swecha PyPI registry"
    }
}

$env:Path = "$env:USERPROFILE\.local\bin;$env:Path"
Write-Success "corpus-client-cli ready"
Write-Info "Note: corpus-client auto-updates on each run -- run reapply.ps1 if patches break"

# --- Step 4: Detect GPU ------------------------------------------------------
Write-Step "Step 4/7  Detecting GPU..."
$gpuJsonLines = python "$Root\lib\detect\detect_gpu.py" --json 2>$null
if (-not $gpuJsonLines) {
    $gpuJsonRaw = '{"brand":"cpu","device_str":"cpu","vram_gb":0,"name":"No GPU","os":"Windows"}'
} else {
    $gpuJsonRaw = ($gpuJsonLines -join " ")
}
$gpuInfo = $gpuJsonRaw | ConvertFrom-Json

# Write GPU info to a temp file instead of passing raw JSON as a CLI argument.
# PowerShell mangles arguments containing embedded double-quotes when calling
# native executables (like python.exe), so a file path is the reliable option.
$gpuJsonFile = Join-Path $env:TEMP "corpus_gpu_info.json"
$gpuJsonRaw | Out-File -FilePath $gpuJsonFile -Encoding utf8 -NoNewline

Write-Host ""
Write-Host "  +--------------------------------------------------+"
Write-Host ("  |  Brand   : " + $gpuInfo.brand)
Write-Host ("  |  Name    : " + $gpuInfo.name)
Write-Host ("  |  VRAM    : " + $gpuInfo.vram_gb + " GB")
Write-Host ("  |  Device  : " + $gpuInfo.device_str)
if ($gpuInfo.cuda_version) { Write-Host ("  |  CUDA    : " + $gpuInfo.cuda_version) }
Write-Host "  +--------------------------------------------------+"
Write-Host ""

# --- Step 5: Install correct PyTorch ----------------------------------------
Write-Step "Step 5/7  Installing GPU-optimized PyTorch..."
$corpusPy = Get-ChildItem "$env:APPDATA\uv\tools\corpus-client-cli" -Recurse -Filter "python.exe" -ErrorAction SilentlyContinue |
    Select-Object -First 1 -ExpandProperty FullName
if (-not $corpusPy) {
    $corpusPy = Get-ChildItem "$env:USERPROFILE\.local\share\uv\tools\corpus-client-cli" -Recurse -Filter "python.exe" -ErrorAction SilentlyContinue |
        Select-Object -First 1 -ExpandProperty FullName
}

& "$Root\lib\install\install_torch_windows.ps1" -Brand $gpuInfo.brand -CudaVersion $gpuInfo.cuda_version -CorpusPython $corpusPy

# --- Step 6: Apply patches ---------------------------------------------------
Write-Step "Step 6/7  Applying corpus-client patches..."
python "$Root\lib\patch\patch_all.py" --gpu-json-file "$gpuJsonFile"

# --- Step 7: Configure environment -------------------------------------------
Write-Step "Step 7/7  Configuring environment..."

$needsNoCompile = $false
if ($gpuInfo.brand -eq "nvidia" -and $gpuInfo.compute_capability_major -ge 12) {
    $needsNoCompile = $true
    [System.Environment]::SetEnvironmentVariable("CORPUS_ASR_NO_COMPILE", "1", "User")
    Write-Success "  Set CORPUS_ASR_NO_COMPILE=1 for Blackwell GPU"
}

# --- Summary ------------------------------------------------------------------
Write-Host ""
Write-Header "Setup Complete!"
Write-Host ""
Write-Host ("  GPU     : " + $gpuInfo.name)
Write-Host ("  Backend : " + $gpuInfo.device_str)
Write-Host ""
Write-Host "  To start contributing compute:"
Write-Host ""
if ($needsNoCompile) {
    Write-Host "    `$env:CORPUS_ASR_NO_COMPILE = '1'"
}
Write-Host "    corpus-client volunteer-compute --always"
Write-Host ""
Write-Host "  To run continuously until stopped:"
Write-Host "    .\run_forever.ps1"
Write-Host ""
Write-Host "  Other useful commands:"
Write-Host "    corpus-client login"
Write-Host "    corpus-client profile"
Write-Host "    .\verify.ps1"
Write-Host "    .\reapply.ps1"
Write-Host ""
Write-Warn "If corpus-client auto-updates and patches break, run: .\reapply.ps1"
Write-Host ""
Write-Success "Happy contributing to Swecha's Indic AI corpus!"

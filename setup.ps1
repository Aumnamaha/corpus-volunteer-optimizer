# corpus-volunteer-optimizer — setup.ps1
# Run from PowerShell as Administrator for best results
param([switch]$Reinstall)
$Root = $PSScriptRoot
. "$Root\lib\utils\colors.ps1"
Write-Header "corpus-volunteer-optimizer (Windows)"

# Step 1: Check Python
Write-Step "Step 1/6  Checking Python..."
try { $pyver = python --version; Write-Success "  $pyver" } catch { Write-Err "Python not found. Install from https://python.org"; exit 1 }

# Step 2: Check uv
Write-Step "Step 2/6  Checking uv..."
if (-not (Get-Command uv -EA SilentlyContinue)) {
    Write-Warn "uv not found — installing..."
    powershell -c "irm https://astral.sh/uv/install.ps1 | iex"
}
Write-Success "uv ready"

# Step 3: Install corpus-client-cli
Write-Step "Step 3/6  Installing corpus-client-cli..."
uv tool install "git+https://code.swecha.org/corpus/corpus-client-cli"
Write-Success "corpus-client-cli installed"

# Step 4: Detect GPU
Write-Step "Step 4/6  Detecting GPU..."
. "$Root\lib\detect\detect_gpu.ps1"
$gpuJson = python "$Root\lib\detect\detect_gpu.py" --json 2>$null

# Step 5: Install PyTorch
Write-Step "Step 5/6  Installing GPU PyTorch..."
$corpusPy = Get-ChildItem "$env:USERPROFILE\.local\share\uv\tools\corpus-client-cli" -Recurse -Filter "python.exe" -EA SilentlyContinue | Select-Object -First 1 -Expand FullName
& "$Root\lib\install\install_torch_windows.ps1" -Brand $global:GPU_BRAND -CudaVersion ($global:GPU_CUDA_VER) -CorpusPython $corpusPy

# Step 6: Patches
Write-Step "Step 6/6  Applying patches..."
python "$Root\lib\patch\patch_all.py" --gpu-json $gpuJson

Write-Header "Setup Complete!"
Write-Info "Run: corpus-client volunteer-compute"

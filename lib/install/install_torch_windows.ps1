param([string]$Brand="cpu", [string]$CudaVersion="", [string]$CorpusPython="")
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
. "$Root\lib\utils\colors.ps1"
Write-Header "Installing PyTorch for Windows ($Brand)"
if (-not $CorpusPython) {
    $CorpusPython = Get-ChildItem "$env:USERPROFILE\.local\share\uv\tools\corpus-client-cli" -Recurse -Filter "python.exe" -EA SilentlyContinue | Select-Object -First 1 -Expand FullName
}
if (-not $CorpusPython) { Write-Err "corpus-client-cli not found"; exit 1 }
switch ($Brand) {
    "nvidia" {
        $map = Get-Content "$Root\config\cuda_map.json" | ConvertFrom-Json
        $major = $CudaVersion.Split(".")[0]
        $url = $map.$major.url
        if (-not $url) { $url = "https://download.pytorch.org/whl/cu124" }
        Write-Info "Using: $url"
        $env:UV_HTTP_TIMEOUT="300"
        uv pip install --python $CorpusPython torch --index-url $url --reinstall
    }
    "intel" {
        uv pip install --python $CorpusPython intel-extension-for-pytorch --extra-index-url https://pytorch-extension.intel.com/release-whl/stable/xpu/us/
    }
    "amd" { Write-Warn "AMD on Windows uses CPU (ROCm not supported on Windows)" }
    default { Write-Info "CPU mode — no changes needed" }
}
& $CorpusPython -c "import torch; print('torch:', torch.__version__); print('CUDA:', torch.cuda.is_available())"
Write-Success "Done"

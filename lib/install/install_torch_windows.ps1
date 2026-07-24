# Windows torch installer -- handles NVIDIA, Intel Arc, AMD (CPU fallback), CPU
param(
    [string]$Brand = "cpu",
    [string]$CudaVersion = "",
    [string]$CorpusPython = ""
)

$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
. "$Root\lib\utils\colors.ps1"

Write-Header "Installing PyTorch for Windows ($Brand)"

if (-not $CorpusPython) {
    # uv on Windows stores tools under AppData\Roaming, NOT .local
    $CorpusPython = Get-ChildItem "$env:APPDATA\uv\tools\corpus-client-cli" -Recurse -Filter "python.exe" -EA SilentlyContinue |
        Select-Object -First 1 -ExpandProperty FullName

    if (-not $CorpusPython) {
        # Fallback: some setups may still use .local
        $CorpusPython = Get-ChildItem "$env:USERPROFILE\.local\share\uv\tools\corpus-client-cli" -Recurse -Filter "python.exe" -EA SilentlyContinue |
            Select-Object -First 1 -ExpandProperty FullName
    }
}

if (-not $CorpusPython) {
    Write-Err "corpus-client-cli Python not found. Install first with:"
    Write-Err "  uv tool install git+https://code.swecha.org/corpus/corpus-client-cli"
    exit 1
}

Write-Info "Using Python: $CorpusPython"

switch ($Brand) {
    "nvidia" {
        $cudaMapPath = "$Root\config\cuda_map.json"
        $cudaMap = Get-Content $cudaMapPath | ConvertFrom-Json
        $major = $CudaVersion.Split(".")[0]
        $entry = $cudaMap.$major
        $wheelUrl = if ($entry) { $entry.url } else { "https://download.pytorch.org/whl/cu124" }

        Write-Info "CUDA version detected: $CudaVersion -> using wheel: $wheelUrl"
        $env:UV_HTTP_TIMEOUT = "300"
        uv pip install --python $CorpusPython torch --index-url $wheelUrl --reinstall
    }
    "intel" {
        Write-Info "Installing Intel Extension for PyTorch (IPEX)..."
        $env:UV_HTTP_TIMEOUT = "300"
        uv pip install --python $CorpusPython intel-extension-for-pytorch --extra-index-url https://pytorch-extension.intel.com/release-whl/stable/xpu/us/
    }
    "amd" {
        Write-Warn "AMD GPU on Windows: ROCm is not supported on Windows."
        Write-Info "Running in CPU mode. For GPU acceleration, use Linux with ROCm."
    }
    default {
        Write-Info "CPU mode -- no torch changes needed"
    }
}

# Verify
& $CorpusPython -c "import torch; print('torch:', torch.__version__); print('CUDA:', torch.cuda.is_available())"
Write-Success "PyTorch installation complete"

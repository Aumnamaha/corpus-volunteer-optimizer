$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$json = python "$Root\lib\detect\detect_gpu.py" --json 2>$null | ConvertFrom-Json
if (-not $json) {
    $global:GPU_BRAND="cpu"; $global:GPU_DEVICE="cpu"; $global:GPU_VRAM=0; return
}
$global:GPU_BRAND=$json.brand; $global:GPU_NAME=$json.name
$global:GPU_VRAM=$json.vram_gb; $global:GPU_DEVICE=$json.device_str
$global:GPU_CUDA_VER=$json.cuda_version; $global:GPU_CC_MAJOR=$json.compute_capability_major
$global:GPU_ROCM_VER=$json.rocm_version; $global:GPU_JSON=$json
Write-Host "  GPU: $($json.name) ($($json.vram_gb) GB) [$($json.device_str)]"

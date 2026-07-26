# Re-apply patches after uv tool upgrade corpus-client-cli
$Root = $PSScriptRoot
. "$Root\lib\utils\colors.ps1"
Write-Header "Re-applying patches after upgrade"

$gpuJsonLines = python "$Root\lib\detect\detect_gpu.py" --json 2>$null
if (-not $gpuJsonLines) {
    $gpuJsonRaw = '{"brand":"cpu","device_str":"cpu","vram_gb":0,"name":"No GPU","os":"Windows"}'
} else {
    $gpuJsonRaw = ($gpuJsonLines -join " ")
}

# Write to temp file to avoid PowerShell's native-exe argument quoting bug
$gpuJsonFile = Join-Path $env:TEMP "corpus_gpu_info.json"
$gpuJsonRaw | Out-File -FilePath $gpuJsonFile -Encoding utf8 -NoNewline

python "$Root\lib\patch\patch_all.py" --gpu-json-file "$gpuJsonFile"

Write-Success "Patches re-applied. Run .\verify.ps1 to confirm."

$Root = $PSScriptRoot
. "$Root\lib\utils\colors.ps1"
Write-Header "Re-applying patches after upgrade"
$gpuJson = python "$Root\lib\detect\detect_gpu.py" --json 2>$null
python "$Root\lib\patch\patch_all.py" --gpu-json $gpuJson
Write-Success "Done. Run verify.ps1 to confirm."

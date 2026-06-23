$Root = $PSScriptRoot
. "$Root\lib\utils\colors.ps1"
Write-Header "Verification"
$py = Get-ChildItem "$env:USERPROFILE\.local\share\uv\tools\corpus-client-cli" -Recurse -Filter "python.exe" -EA SilentlyContinue | Select-Object -First 1 -Expand FullName
if ($py) {
    & $py -c "import torch; print('torch:', torch.__version__); print('CUDA:', torch.cuda.is_available())"
    Write-Success "Verification complete"
} else {
    Write-Err "corpus-client-cli not found"
}

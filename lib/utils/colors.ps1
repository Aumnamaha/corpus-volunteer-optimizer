function Write-Info    { param($msg) Write-Host "i  $msg" -ForegroundColor Cyan }
function Write-Success { param($msg) Write-Host "v  $msg" -ForegroundColor Green }
function Write-Warn    { param($msg) Write-Host "!  $msg" -ForegroundColor Yellow }
function Write-Err     { param($msg) Write-Host "x  $msg" -ForegroundColor Red }
function Write-Step    { param($msg) Write-Host "-> $msg" -ForegroundColor White }
function Write-Header  {
    param($msg)
    $line = "=" * 60
    Write-Host "`n$line" -ForegroundColor Cyan
    Write-Host "  $msg"  -ForegroundColor Cyan
    Write-Host "$line`n"  -ForegroundColor Cyan
}

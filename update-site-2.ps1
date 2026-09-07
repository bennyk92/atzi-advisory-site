# ============================================================
#  ATZI Advisory — site update, part 2
#  Fixes the 5 items that were skipped: they contain an en-dash (–)
#  which the first script didn't match correctly.
#  Run from: C:\Users\benny\Projects\ATZI-Advisory-Site
#    powershell -ExecutionPolicy Bypass -File .\update-site-2.ps1
# ============================================================

$file = "index.html"
if (-not (Test-Path $file)) { Write-Host "ERROR: index.html not found. cd to the site folder first." -ForegroundColor Red; exit 1 }

Copy-Item $file "index.backup2.html" -Force
Write-Host "Backup saved as index.backup2.html" -ForegroundColor Yellow

$h = Get-Content $file -Raw -Encoding UTF8
$D = [string][char]0x2013   # en-dash
$changes = 0

# {D} in the strings below is swapped for a real en-dash before matching
function T([string]$s) { return $s.Replace('{D}', $script:D) }
function Swap([string]$old, [string]$new, [string]$label) {
    $o = T $old; $n = T $new
    if ($script:h.Contains($o)) { $script:h = $script:h.Replace($o, $n); $script:changes++; Write-Host "  OK  $label" -ForegroundColor Green }
    else { Write-Host "  --  $label (not found)" -ForegroundColor DarkGray }
}

Write-Host "`nApplying en-dash fixes..." -ForegroundColor Cyan

Swap '<span class="v">$1M {D} $15M</span>' '<span class="v">$1M {D} $20M</span>' 'Stat card: loan size to $20M'

Swap '<span class="v b">48{D}72 hrs</span>' '<span class="v b">24{D}48 hrs</span>' 'Stat card: term sheets 24-48 hrs'

Swap 'debt from $1M{D}$15M.' 'debt from $1M{D}$20M.' 'Social/OG description: loan range'

Swap 'Typically 48{D}72 hours. We present the options' 'Typically 24{D}48 hours once supporting documents are in. We present the options' 'Process step 4: term sheet timing'

Swap '<li>Term sheets typically within 48{D}72 hours</li>' '<li>Term sheets typically within 24{D}48 hours of documents</li>' 'Sidebar: term sheet timing'

Set-Content -Path $file -Value $h -Encoding UTF8 -NoNewline

Write-Host "`n$changes of 5 fixes applied." -ForegroundColor Cyan

# ---- verification ----
Write-Host "`nVerifying (all should read 0):" -ForegroundColor Cyan
$v = Get-Content $file -Raw -Encoding UTF8
$old15  = ([regex]::Matches($v, [regex]::Escape('$15M'))).Count
$old4872 = ([regex]::Matches($v, '48' + [regex]::Escape($D) + '72')).Count
$old279 = ([regex]::Matches($v, [regex]::Escape('279M'))).Count
Write-Host ("  leftover `$15M      : {0}" -f $old15)
Write-Host ("  leftover 48-72 hrs : {0}" -f $old4872)
Write-Host ("  leftover `$279M     : {0}" -f $old279)
if ($old15 -eq 0 -and $old4872 -eq 0 -and $old279 -eq 0) {
    Write-Host "`nAll clear - every old value is gone.`n" -ForegroundColor Green
} else {
    Write-Host "`nSomething is still left over - send me the numbers above.`n" -ForegroundColor Red
}
Write-Host "Preview:  start index.html" -ForegroundColor White
Write-Host "Restore:  Copy-Item index.backup2.html index.html -Force`n" -ForegroundColor DarkGray

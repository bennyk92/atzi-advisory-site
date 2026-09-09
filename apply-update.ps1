# ============================================================
#  ATZI Advisory - update: engagement terms moved to a popup
#  after Submit, plus a signed copy emailed to the borrower.
#
#  Put index.new.html in this folder first, then run:
#    powershell -ExecutionPolicy Bypass -File .\apply-update.ps1
#
#  Your Apps Script URL, phone number and email are carried
#  over from your current index.html automatically.
# ============================================================

if (-not (Test-Path "index.html"))     { Write-Host "ERROR: index.html not found. cd to the site folder." -ForegroundColor Red; exit 1 }
if (-not (Test-Path "index.new.html")) { Write-Host "ERROR: index.new.html not found. Download it into this folder first." -ForegroundColor Red; exit 1 }

$old = Get-Content "index.html"     -Raw -Encoding UTF8
$new = Get-Content "index.new.html" -Raw -Encoding UTF8

Copy-Item "index.html" "index.backup-terms.html" -Force
Write-Host "Backup saved as index.backup-terms.html" -ForegroundColor Yellow
Write-Host ""

# --- carry over the Apps Script URL ---
$m = [regex]::Match($old, "var GOOGLE_SCRIPT_URL = '([^']*)'")
if ($m.Success -and $m.Groups[1].Value -ne 'YOUR_GOOGLE_SCRIPT_URL') {
    $new = [regex]::Replace($new, "var GOOGLE_SCRIPT_URL = '[^']*'", "var GOOGLE_SCRIPT_URL = '" + $m.Groups[1].Value + "'")
    Write-Host "  OK  Apps Script URL carried over" -ForegroundColor Green
} else { Write-Host "  !!  Could not find your Apps Script URL - check it after this runs" -ForegroundColor Yellow }

# --- carry over the phone number ---
$t = [regex]::Match($old, 'tel:\+(\d+)')
if ($t.Success -and $t.Groups[1].Value -ne '10000000000') {
    $new = [regex]::Replace($new, 'tel:\+\d+', 'tel:+' + $t.Groups[1].Value)
    Write-Host "  OK  Phone link carried over" -ForegroundColor Green
}
$d = [regex]::Match($old, '>(\(\d{3}\) \d{3}-\d{4})</a>')
if ($d.Success -and $d.Groups[1].Value -ne '(000) 000-0000') {
    $new = $new.Replace('(000) 000-0000', $d.Groups[1].Value)
    Write-Host "  OK  Phone display carried over" -ForegroundColor Green
}

# --- carry over the email if it differs ---
$e = [regex]::Match($old, 'mailto:([^"]+)')
if ($e.Success -and $e.Groups[1].Value -ne 'ben.k@atziadvisory.com') {
    $new = $new.Replace('ben.k@atziadvisory.com', $e.Groups[1].Value)
    Write-Host "  OK  Email carried over" -ForegroundColor Green
}

$utf8 = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText((Join-Path $PWD "index.html"), $new, $utf8)
Remove-Item "index.new.html" -Force

# --- verification ---
$v = Get-Content "index.html" -Raw -Encoding UTF8
$open   = ([regex]::Matches($v, '<div')).Count
$close  = ([regex]::Matches($v, '</div>')).Count
$modal  = $v.Contains('id="agOvl"')
$before = $v.IndexOf('id="agOvl"') -lt $v.LastIndexOf('<script>')
$url    = -not $v.Contains('YOUR_GOOGLE_SCRIPT_URL')

Write-Host ""
Write-Host "Verification:" -ForegroundColor Cyan
Write-Host ("  div tags open / close     : {0} / {1}" -f $open, $close)
Write-Host ("  terms popup present       : {0}" -f $modal)
Write-Host ("  popup loads before script : {0}" -f $before)
Write-Host ("  script URL set            : {0}" -f $url)
Write-Host ""
if ($open -eq $close -and $modal -and $before -and $url) {
    Write-Host "  All checks passed - safe to push." -ForegroundColor Green
} else {
    Write-Host "  Something is off - send me the numbers above before pushing." -ForegroundColor Red
}
Write-Host ""
Write-Host "Restore:  Copy-Item index.backup-terms.html index.html -Force" -ForegroundColor DarkGray

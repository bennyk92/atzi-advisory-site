# ============================================================
#  ATZI Advisory - URGENT FIX
#  The engagement-agreement block was inserted with a missing
#  closing </div> and a missing acceptance checkbox. That stray
#  div wrapped the Lender and Referral Partner forms inside the
#  borrower form, so they never appeared.
#  Run from your site folder:
#    powershell -ExecutionPolicy Bypass -File .\fix-forms.ps1
# ============================================================

$file = "index.html"
if (-not (Test-Path $file)) { Write-Host "ERROR: index.html not found." -ForegroundColor Red; exit 1 }
Copy-Item $file "index.backup-fix.html" -Force
Write-Host "Backup saved as index.backup-fix.html" -ForegroundColor Yellow

$h = Get-Content $file -Raw -Encoding UTF8

$anchor = 'termination.</p>' + "`r`n" + '            </div>' + "`r`n" + '          <div class="consent"><input type="checkbox" required id="c1">'
$anchorLF = 'termination.</p>' + "`n" + '            </div>' + "`n" + '          <div class="consent"><input type="checkbox" required id="c1">'

$fixed = 'termination.</p>' + "`r`n" + '            </div>' + "`r`n" +
'            <div class="consent" style="margin-top:12px"><input type="checkbox" required id="cAgree" name="Agreement Accepted" value="Accepted"><label for="cAgree" style="font-weight:400;margin:0">I have read and agree to the engagement terms above, including the exclusivity and fee provisions.</label></div>' + "`r`n" +
'          </div>' + "`r`n" +
'          <div class="consent"><input type="checkbox" required id="c1">'

$done = $false
if ($h.Contains($anchor))        { $h = $h.Replace($anchor, $fixed);   $done = $true }
elseif ($h.Contains($anchorLF))  { $h = $h.Replace($anchorLF, $fixed); $done = $true }

if ($done) {
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText((Join-Path $PWD $file), $h, $utf8)
    Write-Host "  OK  Closing div restored and acceptance checkbox added" -ForegroundColor Green
} else {
    if ($h.Contains('id="cAgree"')) { Write-Host "  --  Already fixed - nothing to do." -ForegroundColor DarkGray }
    else { Write-Host "  !!  Could not find the broken section. Tell me and we will look together." -ForegroundColor Red }
}

# verification
$v = Get-Content $file -Raw -Encoding UTF8
$hasAgree = $v.Contains('id="cAgree"')
$open  = ([regex]::Matches($v, '<div')).Count
$close = ([regex]::Matches($v, '</div>')).Count
Write-Host ""
Write-Host "Verification:" -ForegroundColor Cyan
Write-Host ("  acceptance checkbox present : {0}" -f $hasAgree)
Write-Host ("  div tags open / close       : {0} / {1}" -f $open, $close)
if ($hasAgree -and $open -eq $close) {
    Write-Host ""
    Write-Host "  All good - divs balanced. Push it up." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "  Still unbalanced - send me these numbers." -ForegroundColor Red
}
Write-Host ""
Write-Host "Restore:  Copy-Item index.backup-fix.html index.html -Force" -ForegroundColor DarkGray

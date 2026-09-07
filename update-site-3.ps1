# ============================================================
#  ATZI Advisory — site update, part 3
#    - footnote under "Term sheets in"
#    - "Closing timeframe in as little as"
#    - rewritten "What we do" section (targeted placement)
#  Run from: C:\Users\benny\Projects\ATZI-Advisory-Site
#    powershell -ExecutionPolicy Bypass -File .\update-site-3.ps1
# ============================================================

$file = "index.html"
if (-not (Test-Path $file)) { Write-Host "ERROR: index.html not found. cd to the site folder first." -ForegroundColor Red; exit 1 }

Copy-Item $file "index.backup3.html" -Force
Write-Host "Backup saved as index.backup3.html" -ForegroundColor Yellow

$h = Get-Content $file -Raw -Encoding UTF8
$D = [string][char]0x2013   # en-dash
$M = [string][char]0x2014   # em-dash
$changes = 0

function T([string]$s) { return $s.Replace('{D}', $script:D).Replace('{M}', $script:M) }
function Swap([string]$old, [string]$new, [string]$label) {
    $o = T $old; $n = T $new
    if ($script:h.Contains($o)) { $script:h = $script:h.Replace($o, $n); $script:changes++; Write-Host "  OK  $label" -ForegroundColor Green }
    else { Write-Host "  --  $label (NOT FOUND)" -ForegroundColor Red }
}

Write-Host "`nApplying changes..." -ForegroundColor Cyan

# ---- 1. CSS so the stat label can carry a small sub-line ----
$cssOld = @'
.stat-row{display:flex;justify-content:space-between;align-items:baseline;padding:17px 0;border-bottom:1px solid var(--line)}
.stat-row:last-child{border-bottom:none}
.stat-row .k{font-size:.86rem;color:var(--muted)}
'@
$cssNew = @'
.stat-row{display:flex;justify-content:space-between;align-items:flex-start;gap:14px;padding:17px 0;border-bottom:1px solid var(--line)}
.stat-row:last-child{border-bottom:none}
.stat-row .k{font-size:.86rem;color:var(--muted);padding-top:5px}
.stat-row .k .sub{display:block;font-size:.72rem;color:#93A2B8;margin-top:4px;line-height:1.4;max-width:190px}
.stat-row .v{text-align:right;white-space:nowrap}
'@
Swap $cssOld $cssNew 'Stat card CSS: sub-line support'

# ---- 2. Footnote under term sheets ----
Swap '<div class="stat-row"><span class="k">Term sheets in</span><span class="v b">24{D}48 hrs</span></div>' `
     '<div class="stat-row"><span class="k">Term sheets in<span class="sub">Upon receipt of initial and supporting files</span></span><span class="v b">24{D}48 hrs</span></div>' `
     'Footnote: upon receipt of files'

# ---- 3. Closing timeframe label ----
Swap '<div class="stat-row"><span class="k">Closing timeframe</span><span class="v">5 business days</span></div>' `
     '<div class="stat-row"><span class="k">Closing timeframe in as little as</span><span class="v">5 business days</span></div>' `
     'Label: closing timeframe in as little as'

# ---- 4. Section heading + lead ----
$headOld = @'
      <h2>A financing desk built around execution</h2>
      <p class="lead">Most borrowers approach one or two lenders they already know and take whatever terms come back. We run a competitive process across an entire network {M} and we do the packaging, the follow-up and the coordination that gets a deal to the closing table.</p>
'@
$headNew = @'
      <h2>Targeted placement, not a mass submission</h2>
      <p class="lead">Most advisors take a deal and push it out to whoever will look at it. That approach wastes weeks on lenders who were never going to fund it, and a deal that has visibly circulated the market gets priced accordingly. We work in the opposite direction: understand the deal first, identify the specific lenders whose criteria and current appetite genuinely fit it, and go to those lenders directly.</p>
'@
Swap $headOld $headNew 'Section heading and lead paragraph'

# ---- 5. Three cards ----
$c1Old = @'
        <h3>Structure</h3>
        <p>We underwrite the deal before it goes out {M} sizing, leverage, sources and uses, exit. A lender sees a clean, credible package, not a pile of documents.</p>
'@
$c1New = @'
        <h3>Understand the deal</h3>
        <p>We underwrite before anything goes out {M} sizing, leverage, sources and uses, sponsor strength and exit. We find the questions a credit committee will ask and answer them inside the package, rather than letting them surface late and kill momentum.</p>
'@
Swap $c1Old $c1New 'Card 1: Understand the deal'

$c2Old = @'
        <h3>Match</h3>
        <p>Every lender has a box {M} asset type, geography, leverage, sponsor profile. We know those boxes and take your deal to the ones that actually fund it.</p>
'@
$c2New = @'
        <h3>Target the right lenders</h3>
        <p>Every lender has a box: asset type, geography, leverage, sponsor profile, and what they are actually funding this quarter. We track those parameters across 60+ capital sources and approach only the handful genuinely positioned to execute your deal.</p>
'@
Swap $c2Old $c2New 'Card 2: Target the right lenders'

$c3Old = @'
        <h3>Close</h3>
        <p>Term sheet through funding: diligence lists, appraisals, title, legal. We chase the items and keep every party moving so the timeline holds.</p>
'@
$c3New = @'
        <h3>Drive it to close</h3>
        <p>Term sheet through funding: diligence lists, appraisal, title, insurance and legal. We chase every item and hold each party to the schedule, because a deal that stalls in diligence is a deal that reprices or dies.</p>
'@
Swap $c3Old $c3New 'Card 3: Drive it to close'

Set-Content -Path $file -Value $h -Encoding UTF8 -NoNewline
Write-Host "`n$changes of 6 change(s) applied." -ForegroundColor Cyan
Write-Host "Preview:  start index.html" -ForegroundColor White
Write-Host "Restore:  Copy-Item index.backup3.html index.html -Force`n" -ForegroundColor DarkGray

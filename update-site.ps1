# ============================================================
#  ATZI Advisory — site update
#  Run from: C:\Users\benny\Projects\ATZI-Advisory-Site
#  Usage:    powershell -ExecutionPolicy Bypass -File .\update-site.ps1
#  Your Web3Forms key, email and phone are left untouched.
# ============================================================

$file = "index.html"
if (-not (Test-Path $file)) { Write-Host "ERROR: index.html not found. cd to the site folder first." -ForegroundColor Red; exit 1 }

Copy-Item $file "index.backup.html" -Force
Write-Host "Backup saved as index.backup.html" -ForegroundColor Yellow

$h = Get-Content $file -Raw -Encoding UTF8
$changes = 0
function Swap([string]$old, [string]$new, [string]$label) {
    if ($script:h.Contains($old)) { $script:h = $script:h.Replace($old, $new); $script:changes++; Write-Host "  OK  $label" -ForegroundColor Green }
    else { Write-Host "  --  $label (not found - may already be updated)" -ForegroundColor DarkGray }
}

Write-Host "`nApplying changes..." -ForegroundColor Cyan

# ---- 1. HERO STAT CARD ----
Swap '<div class="stat-row"><span class="k">Loan size</span><span class="v">$1M &#8211; $15M</span></div>' `
     '<div class="stat-row"><span class="k">Loan size</span><span class="v">$1M &#8211; $20M</span></div>' `
     'Stat card: loan size to $20M'

Swap '<div class="stat-row"><span class="k">Term sheets in</span><span class="v b">48&#8211;72 hrs</span></div>' `
     '<div class="stat-row"><span class="k">Term sheets in</span><span class="v b">24&#8211;48 hrs</span></div>' `
     'Stat card: term sheets 24-48 hrs'

Swap '<div class="stat-row"><span class="k">Lender network</span><span class="v">60+</span></div>' `
     '<div class="stat-row"><span class="k">Closing timeframe</span><span class="v">5 business days</span></div>' `
     'Stat card: closing timeframe replaces lender network'

Swap '<div class="stat-row"><span class="k">Advisory fee</span><span class="v">1% at close</span></div>' `
     '<div class="stat-row"><span class="k">Client referrals</span><span class="v">20% of fee</span></div>' `
     'Stat card: client referrals replaces advisory fee'

# ---- 2. LOAN RANGE EVERYWHERE ----
Swap 'from $1M to $15M.' 'from $1M to $20M.' 'Hero copy: loan range'
Swap 'between $1M and $15M' 'between $1M and $20M' 'Products intro: loan range'
Swap 'We focus on the $1M to $15M middle market.' 'We focus on the $1M to $20M middle market.' 'FAQ: loan sizes'
Swap 'debt from $1M&#8211;$15M.' 'debt from $1M&#8211;$20M.' 'OG description: loan range'

# ---- 3. TIMING LANGUAGE ----
Swap 'Typically 48&#8211;72 hours. We present the options' `
     'Typically 24&#8211;48 hours once supporting documents are in. We present the options' `
     'Process step 4: term sheet timing'

Swap 'For a complete submission, term sheets typically come back within 48 to 72 hours.' `
     'Term sheets typically come back within 24 to 48 hours after supporting documents are submitted.' `
     'FAQ: term sheet timing'

Swap 'We manage the checklist, coordinate appraisal, title, insurance and legal, and keep every party accountable to the closing date.' `
     'We manage the checklist, coordinate appraisal, title, insurance and legal, and keep every party accountable to the closing date. On the right deal, closings can happen in as little as 5 business days.' `
     'Process step 5: closing speed'

# ---- 4. REFERRAL FEE ----
Swap '<li>Term sheets typically within 48&#8211;72 hours</li>' `
     '<li>Term sheets typically within 24&#8211;48 hours of documents</li>' `
     'Sidebar: term sheet timing'

Swap '<li>Fee-share arrangements available</li>' `
     '<li>20% of our advisory fee on closed referrals</li>' `
     'Referral partner card: 20% fee share'

# ---- 5. REMOVE TRACK RECORD STATS (keep heading + wording) ----
$bstats = @'
    <div class="bstats">
      <div class="bstat"><div class="n">$279M+</div><div class="l">Total transaction volume</div></div>
      <div class="bstat"><div class="n">$265M+</div><div class="l">Multifamily sales</div></div>
      <div class="bstat"><div class="n">46</div><div class="l">Closed transactions</div></div>
      <div class="bstat"><div class="n">60+</div><div class="l">Lender relationships</div></div>
    </div>
'@
Swap $bstats '' 'Removed track record stat boxes'
Swap '<div class="eyebrow" style="color:#7FA9F5">Track record</div>' `
     '<div class="eyebrow" style="color:#7FA9F5">Experience</div>' `
     'Band eyebrow: Track record -> Experience'

# ---- 6. HERO TRUSTLINE ----
Swap '<span><b>$279M+</b> transacted</span>' `
     '<span><b>$1M&#8211;$20M</b> loan sizes</span>' `
     'Trustline: removed $279M claim'

# ---- 7. CURRENCY FORMATTING ON MONEY FIELDS ----
$anchor = "document.getElementById('yr').textContent=new Date().getFullYear();"
$money = @'
document.getElementById('yr').textContent=new Date().getFullYear();

// --- live currency formatting on dollar fields ---
(function(){
  var moneyFields=['Loan Amount','Value','Existing Debt'];
  function fmt(el){
    var digits=el.value.replace(/[^0-9]/g,'');
    if(!digits){el.value='';return;}
    el.value='$'+parseInt(digits,10).toLocaleString('en-US');
  }
  document.querySelectorAll('input').forEach(function(el){
    if(moneyFields.indexOf(el.getAttribute('name'))===-1) return;
    el.setAttribute('inputmode','numeric');
    el.addEventListener('input',function(){
      var atEnd=el.selectionStart===el.value.length;
      fmt(el);
      if(atEnd){el.setSelectionRange(el.value.length,el.value.length);}
    });
    el.addEventListener('blur',function(){fmt(el)});
  });
})();
'@
Swap $anchor $money 'Currency auto-formatting on dollar fields'

Set-Content -Path $file -Value $h -Encoding UTF8 -NoNewline
Write-Host "`n$changes change(s) applied to index.html" -ForegroundColor Cyan
Write-Host "Preview it with:  start index.html" -ForegroundColor White
Write-Host "If anything looks wrong, restore with:  Copy-Item index.backup.html index.html -Force`n" -ForegroundColor DarkGray

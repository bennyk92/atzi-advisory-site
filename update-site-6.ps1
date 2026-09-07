# ============================================================
#  ATZI Advisory - site update, part 6
#   - email changed to ben.k@atziadvisory.com
#   - lender form: min/max loan size with $ formatting
#   - lender form: Max LTV and Max LTC
#   - lender form: loan programs + asset classes checkboxes
#  Run from your site folder:
#    powershell -ExecutionPolicy Bypass -File .\update-site-6.ps1
# ============================================================

$file = "index.html"
if (-not (Test-Path $file)) { Write-Host "ERROR: index.html not found." -ForegroundColor Red; exit 1 }
Copy-Item $file "index.backup6.html" -Force
Write-Host "Backup saved as index.backup6.html" -ForegroundColor Yellow

$h = Get-Content $file -Raw -Encoding UTF8
$EN  = [string][char]0x2013
$ELL = [string][char]0x2026
$changes = 0

function Swap([string]$old, [string]$new, [string]$label) {
    $o = $old.Replace('{ENDASH}', $script:EN).Replace('{ELL}', $script:ELL)
    if ($script:h.Contains($o)) { $script:h = $script:h.Replace($o, $new); $script:changes++; Write-Host "  OK  $label" -ForegroundColor Green }
    else { Write-Host "  --  $label (NOT FOUND)" -ForegroundColor Red }
}

Write-Host ""
Write-Host "Applying changes..." -ForegroundColor Cyan

# --- 1. email ---
$before = ([regex]::Matches($h, 'info@atziadvisory\.com')).Count
$h = $h.Replace('info@atziadvisory.com', 'ben.k@atziadvisory.com')
if ($before -gt 0) { $changes++; Write-Host "  OK  Email updated to ben.k@atziadvisory.com ($before place(s))" -ForegroundColor Green }
else { Write-Host "  --  Email already updated" -ForegroundColor DarkGray }

# --- 2. checkbox grid styles ---
$cssNew = @'
.optgrid{display:grid;grid-template-columns:repeat(3,1fr);gap:7px 14px;border:1px solid var(--line);border-radius:10px;padding:14px 16px;background:#FAFCFF}
.optgrid label{display:flex;align-items:center;gap:7px;font-size:.85rem;font-weight:400;color:var(--body);margin:0;cursor:pointer}
.optgrid input{width:auto;margin:0;flex:0 0 auto}
.optlabel{font-size:.78rem;font-weight:700;color:var(--blue);letter-spacing:.06em;text-transform:uppercase;margin:14px 0 7px}
@media(max-width:640px){.optgrid{grid-template-columns:1fr 1fr}}

'@
Swap '.drop{border:1.5px dashed #C6D3E6;' ($cssNew + '.drop{border:1.5px dashed #C6D3E6;') 'Checkbox grid styles'

# --- 3. lender form fields ---
$lenderNew = @'
            <div class="field"><label>Minimum loan size</label><input name="Loan Size Min" placeholder="$" inputmode="numeric"></div>
            <div class="field"><label>Maximum loan size</label><input name="Loan Size Max" placeholder="$" inputmode="numeric"></div>
            <div class="field full"><label>What this lender funds <span style="font-weight:400;color:var(--muted)">(select all that apply)</span></label>
              <div class="optlabel">Loan programs</div>
              <div class="optgrid"><label><input type="checkbox" name="Programs" value="Bridge">Bridge</label><label><input type="checkbox" name="Programs" value="Hard money">Hard money</label><label><input type="checkbox" name="Programs" value="Construction / ground-up">Construction / ground-up</label><label><input type="checkbox" name="Programs" value="New development">New development</label><label><input type="checkbox" name="Programs" value="Acquisition">Acquisition</label><label><input type="checkbox" name="Programs" value="Refinance">Refinance</label><label><input type="checkbox" name="Programs" value="Cash-out refinance">Cash-out refinance</label><label><input type="checkbox" name="Programs" value="Value-add / rehab">Value-add / rehab</label><label><input type="checkbox" name="Programs" value="Fix & flip">Fix & flip</label><label><input type="checkbox" name="Programs" value="DSCR">DSCR</label><label><input type="checkbox" name="Programs" value="Permanent / conventional">Permanent / conventional</label><label><input type="checkbox" name="Programs" value="Agency (Fannie/Freddie)">Agency (Fannie/Freddie)</label><label><input type="checkbox" name="Programs" value="SBA">SBA</label><label><input type="checkbox" name="Programs" value="CMBS">CMBS</label><label><input type="checkbox" name="Programs" value="Land loan">Land loan</label><label><input type="checkbox" name="Programs" value="Mezzanine / preferred equity">Mezzanine / preferred equity</label><label><input type="checkbox" name="Programs" value="Note purchase">Note purchase</label><label><input type="checkbox" name="Programs" value="Fix & hold">Fix & hold</label></div>
              <div class="optlabel">Asset classes</div>
              <div class="optgrid"><label><input type="checkbox" name="Asset Classes" value="Multifamily">Multifamily</label><label><input type="checkbox" name="Asset Classes" value="Single family">Single family</label><label><input type="checkbox" name="Asset Classes" value="Spec home">Spec home</label><label><input type="checkbox" name="Asset Classes" value="Land">Land</label><label><input type="checkbox" name="Asset Classes" value="Retail">Retail</label><label><input type="checkbox" name="Asset Classes" value="Industrial">Industrial</label><label><input type="checkbox" name="Asset Classes" value="Office">Office</label><label><input type="checkbox" name="Asset Classes" value="Mixed-use">Mixed-use</label><label><input type="checkbox" name="Asset Classes" value="Healthcare / senior living">Healthcare / senior living</label><label><input type="checkbox" name="Asset Classes" value="Hospitality">Hospitality</label><label><input type="checkbox" name="Asset Classes" value="Self-storage">Self-storage</label><label><input type="checkbox" name="Asset Classes" value="Mobile home parks">Mobile home parks</label><label><input type="checkbox" name="Asset Classes" value="Student housing">Student housing</label><label><input type="checkbox" name="Asset Classes" value="Special purpose">Special purpose</label></div>
            </div>
            <div class="field full"><label>Lending geography</label><input name="Geography" placeholder="e.g. Southeast US, nationwide, NY metro only"></div>
            <div class="field"><label>Max LTV <span style="font-weight:400;color:var(--muted)">(deal by deal)</span></label><input name="Max LTV" placeholder="e.g. 75%" inputmode="numeric"></div>
            <div class="field"><label>Max LTC <span style="font-weight:400;color:var(--muted)">(deal by deal)</span></label><input name="Max LTC" placeholder="e.g. 85%" inputmode="numeric"></div>
            <div class="field"><label>Typical close timeline</label><input name="Close Timeline" placeholder="e.g. 21 days"></div>
'@
$lenderOld = @'
<div class="field"><label>Loan size range</label><input name="Loan Size Range" placeholder="e.g. $1M {ENDASH} $25M"></div>
            <div class="field full"><label>Products offered</label><input name="Products" placeholder="Bridge, construction, permanent, mezzanine{ELL}"></div>
            <div class="field full"><label>Asset types &amp; geography</label><input name="Asset Types and Geography" placeholder="e.g. multifamily and industrial, Southeast US"></div>
            <div class="field"><label>Max leverage</label><input name="Max Leverage" placeholder="e.g. 75% LTC"></div>
            <div class="field"><label>Typical close timeline</label><input name="Close Timeline" placeholder="e.g. 21 days"></div>
'@
Swap $lenderOld $lenderNew 'Lender form: loan size, LTV/LTC, programs, asset classes'

# --- 4. currency + percentage formatting ---
$moneyNew = @'
// --- live currency formatting (application + lender money fields) ---
(function(){
  var money=['Loan Amount','Value','Existing Debt','Loan Size Min','Loan Size Max'];
  function fmt(el){
    var d=el.value.replace(/[^0-9]/g,'');
    el.value=d?'$'+parseInt(d,10).toLocaleString('en-US'):'';
  }
  document.querySelectorAll('input').forEach(function(el){
    if(money.indexOf(el.getAttribute('name'))===-1) return;
    el.setAttribute('inputmode','numeric');
    el.addEventListener('input',function(){
      var atEnd=el.selectionStart===el.value.length;
      fmt(el);
      if(atEnd) el.setSelectionRange(el.value.length,el.value.length);
    });
    el.addEventListener('blur',function(){fmt(el)});
  });
  // percentage fields
  ['Max LTV','Max LTC'].forEach(function(n){
    var el=document.querySelector('input[name="'+n+'"]');
    if(!el) return;
    el.addEventListener('blur',function(){
      var v=el.value.replace(/[^0-9.]/g,'');
      el.value=v?v+'%':'';
    });
    el.addEventListener('focus',function(){el.value=el.value.replace('%','')});
  });
})();
'@
Swap 'var MAX_FILE=35*1024*1024;' ("var MAX_FILE=35*1024*1024;`r`n`r`n" + $moneyNew) 'Currency and percentage formatting'

# --- 5. collect checkbox groups on submit ---
$collectOld = @'
    var fields={};
    new FormData(form).forEach(function(v,k){
      if(['access_key','subject','from_name','botcheck'].indexOf(k)===-1&&v) fields[k]=v;
    });
'@
$collectNew = @'
    var fields={}, multi={};
    new FormData(form).forEach(function(v,k){
      if(['access_key','subject','from_name','botcheck'].indexOf(k)!==-1||!v) return;
      if(k==='Programs'||k==='Asset Classes'){ (multi[k]=multi[k]||[]).push(v); return; }
      fields[k]=v;
    });
    Object.keys(multi).forEach(function(k){ fields[k]=multi[k].join(', ') });
'@
Swap $collectOld $collectNew 'Multi-select collection on submit'

$utf8 = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText((Join-Path $PWD $file), $h, $utf8)

Write-Host ""
Write-Host "$changes change(s) applied." -ForegroundColor Cyan
Write-Host "REMINDER: update Code.gs in Apps Script and redeploy a NEW VERSION," -ForegroundColor Yellow
Write-Host "          otherwise the new lender fields will not appear in Sheets." -ForegroundColor Yellow
Write-Host ""
Write-Host "Restore:  Copy-Item index.backup6.html index.html -Force" -ForegroundColor DarkGray

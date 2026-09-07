# ============================================================
#  ATZI Advisory - site update, part 7
#   - "presented to lenders before?" question with follow-ups
#   - exclusive engagement agreement with required acceptance
#   - Client Portal link in the nav
#   - success message now links to the client portal
#  Run from your site folder:
#    powershell -ExecutionPolicy Bypass -File .\update-site-7.ps1
# ============================================================

$file = "index.html"
if (-not (Test-Path $file)) { Write-Host "ERROR: index.html not found." -ForegroundColor Red; exit 1 }
Copy-Item $file "index.backup7.html" -Force
Write-Host "Backup saved as index.backup7.html" -ForegroundColor Yellow

$h = Get-Content $file -Raw -Encoding UTF8
$EM = [string][char]0x2014
$changes = 0
function Swap([string]$old, [string]$new, [string]$label) {
    $o = $old.Replace('{EM}', $script:EM); $n = $new.Replace('{EM}', $script:EM)
    if ($script:h.Contains($o)) { $script:h = $script:h.Replace($o, $n); $script:changes++; Write-Host "  OK  $label" -ForegroundColor Green }
    else { Write-Host "  --  $label (NOT FOUND)" -ForegroundColor Red }
}

Write-Host ""
Write-Host "Applying changes..." -ForegroundColor Cyan

# 1. styles
$css = @'
.agbox{border:1px solid var(--line);border-radius:11px;background:#FAFCFF;padding:18px 20px;max-height:210px;overflow-y:auto;font-size:.86rem;line-height:1.6;color:var(--body)}
.agbox h4{font-family:var(--sans);font-size:.8rem;letter-spacing:.08em;text-transform:uppercase;color:var(--blue);margin:14px 0 5px;font-weight:700}
.agbox h4:first-child{margin-top:0}
.agbox p{margin-bottom:9px;font-size:.86rem}
.cond{display:none;border-left:3px solid var(--blue);padding-left:16px;margin-top:4px}
.cond.on{display:block}

'@
Swap '.optgrid{display:grid;' ($css + '.optgrid{display:grid;') 'Agreement and conditional styles'

# 2. prior-lender question
$prior = @'
<div class="field full"><label>Has this property been presented to any lenders in the past? <span class="req">*</span></label>
              <select name="Previously Presented" id="prevSel" required>
                <option value="">Select&hellip;</option>
                <option>No</option>
                <option>Yes</option>
              </select>
              <div class="hint">This matters. Lenders price a deal differently once it has been shopped, so knowing where it has been lets us target lenders who have not already seen it.</div>
            </div>
            
'@
Swap '<div class="field full"><label>Deal summary</label>' ($prior + '<div class="field full"><label>Deal summary</label>') 'Previously-presented-to-lenders question'

# 3. engagement agreement
$agree = @'
<div class="field full" style="margin-top:6px">
            <label>Engagement terms <span class="req">*</span></label>
            <div class="agbox">
              <h4>Exclusive engagement</h4>
              <p>By submitting this application, you engage ATZI Advisory ("the Advisor") on an exclusive basis to source, structure and place financing for the property identified above, for a period of ninety (90) days from the date of submission unless extended or terminated in writing.</p>
              <h4>Exclusivity and disclosure</h4>
              <p>During the engagement, you agree to work exclusively with the Advisor in procuring a lender for this transaction. If you engage, or intend to engage, another advisor, broker or intermediary for this property during the engagement period, you must notify the Advisor in writing or verbally before doing so.</p>
              <p>If financing for this property is closed through another advisor, broker or intermediary during the engagement period without such disclosure, a fee equal to the Advisor's standard advisory fee of one percent (1%) of the financed amount may become due and payable to the Advisor.</p>
              <h4>Direct lender contact</h4>
              <p>Lenders introduced to you by the Advisor are introduced in confidence. Closing a transaction directly with an introduced lender, or through a third party, in order to avoid the Advisor's fee, does not relieve you of the fee obligation.</p>
              <h4>Fees</h4>
              <p>The Advisor's fee is one percent (1%) of the financed amount, earned upon closing and payable from loan proceeds. No fee is due if no loan closes. There are no upfront fees, retainers or application charges.</p>
              <h4>No commitment to lend</h4>
              <p>The Advisor is not a lender and does not commit to provide financing. All financing is subject to third-party lender approval, underwriting and final documentation. Nothing here guarantees a loan, specific terms, or a closing timeline.</p>
              <h4>Termination</h4>
              <p>Either party may terminate this engagement with written notice. Fee obligations survive termination for any lender introduced by the Advisor during the engagement period, for a period of six (6) months following termination.</p>
            </div>
          
'@
$oldConsent = '<div class="consent"><input type="checkbox" required id="c1"><label for="c1" style="font-weight:400;margin:0">I confirm the information provided is accurate and authorize ATZI Advisory to review this request and present it to prospective lenders on a confidential basis.</label></div>'
Swap $oldConsent ($agree + $oldConsent) 'Exclusive engagement agreement'

# 4. conditional logic
$condJs = @'
// --- conditional: previously presented to lenders ---
(function(){
  var sel=document.getElementById('prevSel'), cond=document.getElementById('prevCond');
  if(!sel||!cond) return;
  var kids=['prevWhen','prevCount','prevWho'].map(function(i){return document.getElementById(i)});
  function sync(){
    var yes=sel.value==='Yes';
    cond.classList.toggle('on',yes);
    kids.forEach(function(el){ if(!el) return; if(yes){el.setAttribute('required','required')} else {el.removeAttribute('required'); el.value=''} });
  }
  sel.addEventListener('change',sync); sync();
})();


'@
Swap "var TYPE={'f-borrower':'Application','f-lender':'Lender','f-partner':'Partner'};" ($condJs + "var TYPE={'f-borrower':'Application','f-lender':'Lender','f-partner':'Partner'};") 'Conditional field logic'

# 5. success message with portal link
$oldOk = @'
      msg.className='msg ok';
      msg.textContent='Thank you {EM} your submission has been received'+
        (files.length?' along with '+files.length+' document'+(files.length>1?'s':''):'')+
        '. We review every inquiry personally and will be in touch shortly.';
'@
$newOk = @'
      msg.className='msg ok';
      var link=(res&&res.portal)?' <a href="'+res.portal+'" style="color:#1B6B47;font-weight:700;text-decoration:underline">Track your file here</a>.':'';
      msg.innerHTML='Thank you {EM} your submission has been received'+
        (files.length?' along with '+files.length+' document'+(files.length>1?'s':''):'')+
        '. A confirmation email is on its way.'+link;
'@
Swap $oldOk $newOk 'Success message links to portal'

# 6. nav link
Swap "<a href=`"#faq`">FAQ</a>`r`n      <a href=`"#apply`" class=`"btn`">Apply for Financing</a>" "<a href=`"#faq`">FAQ</a>`r`n      <a href=`"portal.html`">Client Portal</a>`r`n      <a href=`"#apply`" class=`"btn`">Apply for Financing</a>" 'Client Portal nav link'
if ($changes -lt 6) {
  Swap "<a href=`"#faq`">FAQ</a>`n      <a href=`"#apply`" class=`"btn`">Apply for Financing</a>" "<a href=`"#faq`">FAQ</a>`n      <a href=`"portal.html`">Client Portal</a>`n      <a href=`"#apply`" class=`"btn`">Apply for Financing</a>" 'Client Portal nav link (alt)'
}

$utf8 = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText((Join-Path $PWD $file), $h, $utf8)

# 7. portal.html - copy in the Apps Script URL from index.html
if (Test-Path "portal.html") {
    $m = [regex]::Match($h, "var GOOGLE_SCRIPT_URL = '([^']*)'")
    if ($m.Success -and $m.Groups[1].Value -ne 'YOUR_GOOGLE_SCRIPT_URL') {
        $p = Get-Content "portal.html" -Raw -Encoding UTF8
        $p = $p.Replace("var GOOGLE_SCRIPT_URL = 'YOUR_GOOGLE_SCRIPT_URL';", "var GOOGLE_SCRIPT_URL = '" + $m.Groups[1].Value + "';")
        [System.IO.File]::WriteAllText((Join-Path $PWD "portal.html"), $p, $utf8)
        Write-Host "  OK  portal.html wired to your Apps Script URL" -ForegroundColor Green
    } else {
        Write-Host "  !!  Could not copy the script URL into portal.html - paste it in manually" -ForegroundColor Yellow
    }
} else {
    Write-Host "  !!  portal.html not found - copy it into this folder, then re-run" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "$changes change(s) applied." -ForegroundColor Cyan
Write-Host "REMINDER: paste the new Code.gs into Apps Script and deploy a NEW VERSION." -ForegroundColor Yellow
Write-Host "Restore:  Copy-Item index.backup7.html index.html -Force" -ForegroundColor DarkGray

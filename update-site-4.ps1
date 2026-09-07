# ============================================================
#  ATZI Advisory - site update, part 4
#  Adds document upload + Google Drive / Sheets backend wiring.
#  Run from: C:\Users\benny\Projects\ATZI-Advisory-Site
#    powershell -ExecutionPolicy Bypass -File .\update-site-4.ps1
# ============================================================

$file = "index.html"
if (-not (Test-Path $file)) { Write-Host "ERROR: index.html not found. cd to the site folder first." -ForegroundColor Red; exit 1 }
Copy-Item $file "index.backup4.html" -Force
Write-Host "Backup saved as index.backup4.html" -ForegroundColor Yellow

$h = Get-Content $file -Raw -Encoding UTF8
$changes = 0
function Swap([string]$old, [string]$new, [string]$label) {
    if ($script:h.Contains($old)) { $script:h = $script:h.Replace($old, $new); $script:changes++; Write-Host "  OK  $label" -ForegroundColor Green }
    else { Write-Host "  --  $label (NOT FOUND)" -ForegroundColor Red }
}

Write-Host "`
Applying changes..." -ForegroundColor Cyan

# ---- 1. upload styles ----
$cssAnchor = @'
.consent{display:flex;gap:10px;align-items:flex-start;font-size:.82rem;color:var(--muted);margin:6px 0 18px}
'@
$cssNew = @'
.drop{border:1.5px dashed #C6D3E6;border-radius:11px;padding:22px;text-align:center;background:#FAFCFF;cursor:pointer;transition:.15s}
.drop:hover,.drop.over{border-color:var(--blue);background:#F2F7FF}
.drop .t{font-weight:600;color:var(--ink);font-size:.94rem}
.drop .s{font-size:.8rem;color:var(--muted);margin-top:4px}
.drop input[type=file]{display:none}
.filelist{margin-top:12px}
.fileitem{display:flex;justify-content:space-between;align-items:center;gap:12px;background:#F5F8FC;border:1px solid var(--line);border-radius:8px;padding:9px 13px;margin-bottom:7px;font-size:.85rem}
.fileitem .nm{color:var(--ink);overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.fileitem .sz{color:var(--muted);font-size:.78rem;white-space:nowrap}
.fileitem .rm{color:#B4402F;cursor:pointer;font-weight:700;border:none;background:none;font-size:1.05rem;line-height:1;padding:0 2px}
.bar{height:5px;background:var(--line);border-radius:4px;overflow:hidden;margin-top:12px;display:none}
.bar.on{display:block}
.bar i{display:block;height:100%;background:var(--blue);width:0;transition:width .25s}
.consent{display:flex;gap:10px;align-items:flex-start;font-size:.82rem;color:var(--muted);margin:6px 0 18px}
'@
Swap $cssAnchor $cssNew 'Upload dropzone styles'

# ---- 2. upload UI in the application form ----
$uiOld = @'
          </div>
          <div class="consent"><input type="checkbox" required id="c1">
'@
$uiNew = @'
<div class="field full">
              <label>Supporting documents <span style="font-weight:400;color:var(--muted)">(optional, speeds up your term sheet)</span></label>
              <label class="drop" id="drop">
                <input type="file" id="files" multiple accept=".pdf,.doc,.docx,.xls,.xlsx,.csv,.jpg,.jpeg,.png,.zip">
                <div class="t">Click to choose files, or drag them here</div>
                <div class="s">Rent roll, operating statements, purchase contract, existing loan terms, PFS, photos<br>PDF, Word, Excel or images &middot; up to 10 MB per file, 25 MB total</div>
              </label>
              <div class="filelist" id="filelist"></div>
              <div class="bar" id="bar"><i></i></div>
            </div>
          </div>
          <div class="consent"><input type="checkbox" required id="c1">
'@
Swap $uiOld $uiNew 'Document upload field'

# ---- 3. replace the submit script ----
$jsStart = '// form submit -> Web3Forms (emails you directly)'
$i = $h.IndexOf($jsStart)
if ($i -ge 0) {
    $j = $h.IndexOf('</script>', $i)
    $newJs = @'
// ============ SUBMISSION HANDLER ============
// Sends form data (and any uploaded documents) to your Google Apps Script
// backend, which files documents in Drive, logs the row in Sheets, and emails you.
var GOOGLE_SCRIPT_URL = 'YOUR_GOOGLE_SCRIPT_URL';

var msg=document.getElementById('msg');
var picked=[];
var MAX_FILE=10*1024*1024, MAX_TOTAL=25*1024*1024;

// ---- file picker ----
var drop=document.getElementById('drop'), input=document.getElementById('files'),
    list=document.getElementById('filelist'), bar=document.getElementById('bar');

function human(b){return b<1024?b+' B':b<1048576?(b/1024).toFixed(0)+' KB':(b/1048576).toFixed(1)+' MB'}
function totalSize(){return picked.reduce(function(t,f){return t+f.size},0)}
function render(){
  if(!list) return;
  list.innerHTML=picked.map(function(f,i){
    return '<div class="fileitem"><span class="nm">'+f.name+'</span><span class="sz">'+human(f.size)+
           ' <button type="button" class="rm" data-i="'+i+'" title="Remove">&times;</button></span></div>';
  }).join('');
  list.querySelectorAll('.rm').forEach(function(b){
    b.onclick=function(){picked.splice(parseInt(b.dataset.i,10),1);render()};
  });
}
function addFiles(fs){
  Array.prototype.forEach.call(fs,function(f){
    if(f.size>MAX_FILE){alert(f.name+' is larger than 10 MB and was skipped.');return}
    if(totalSize()+f.size>MAX_TOTAL){alert('Total upload limit is 25 MB. '+f.name+' was skipped.');return}
    picked.push(f);
  });
  render();
}
if(input){input.addEventListener('change',function(){addFiles(input.files);input.value=''})}
if(drop){
  ['dragenter','dragover'].forEach(function(ev){drop.addEventListener(ev,function(e){e.preventDefault();drop.classList.add('over')})});
  ['dragleave','drop'].forEach(function(ev){drop.addEventListener(ev,function(e){e.preventDefault();drop.classList.remove('over')})});
  drop.addEventListener('drop',function(e){if(e.dataTransfer&&e.dataTransfer.files)addFiles(e.dataTransfer.files)});
}
function readFile(f){
  return new Promise(function(res,rej){
    var r=new FileReader();
    r.onload=function(){res({name:f.name,mimeType:f.type||'application/octet-stream',data:r.result.split(',')[1]})};
    r.onerror=rej;
    r.readAsDataURL(f);
  });
}

// ---- submit ----
var TYPE={'f-borrower':'Application','f-lender':'Lender','f-partner':'Partner'};
document.querySelectorAll('form.pane').forEach(function(form){
  form.addEventListener('submit',function(e){
    e.preventDefault();
    if(!form.checkValidity()){form.reportValidity();return}
    var btn=form.querySelector('button[type=submit]'), original=btn.textContent;
    var isApp=form.id==='f-borrower';
    btn.disabled=true; btn.textContent=(isApp&&picked.length)?'Uploading…':'Sending…';
    if(isApp&&picked.length&&bar){bar.classList.add('on');bar.querySelector('i').style.width='25%'}

    var fields={};
    new FormData(form).forEach(function(v,k){
      if(['access_key','subject','from_name','botcheck'].indexOf(k)===-1&&v) fields[k]=v;
    });

    var job=(isApp&&picked.length)?Promise.all(picked.map(readFile)):Promise.resolve([]);
    job.then(function(files){
      if(bar) bar.querySelector('i').style.width='65%';
      return fetch(GOOGLE_SCRIPT_URL,{
        method:'POST',
        headers:{'Content-Type':'text/plain;charset=utf-8'},
        body:JSON.stringify({formType:TYPE[form.id]||'Application',fields:fields,files:files})
      });
    }).then(function(r){return r.json()}).then(function(res){
      if(bar) bar.querySelector('i').style.width='100%';
      if(res&&res.success){
        msg.className='msg ok';
        msg.textContent='Thank you — your submission has been received'+
          ((isApp&&picked.length)?' along with '+picked.length+' document'+(picked.length>1?'s':''):'')+
          '. We review every inquiry personally and will be in touch shortly.';
        form.reset(); picked=[]; render();
        msg.scrollIntoView({behavior:'smooth',block:'center'});
      }else{throw new Error((res&&res.error)||'Failed')}
    }).catch(function(){
      msg.className='msg err';
      msg.innerHTML='Something went wrong sending your submission. Please email us directly at <a href="mailto:info@atziadvisory.com">info@atziadvisory.com</a>.';
      msg.scrollIntoView({behavior:'smooth',block:'center'});
    }).finally(function(){
      btn.disabled=false; btn.textContent=original;
      if(bar) setTimeout(function(){bar.classList.remove('on');bar.querySelector('i').style.width='0'},700);
    });
  });
});

'@
    $h = $h.Substring(0, $i) + $newJs + $h.Substring($j)
    $changes++
    Write-Host "  OK  Submission handler rewired to Google backend" -ForegroundColor Green
} else {
    Write-Host "  --  Submission handler (NOT FOUND)" -ForegroundColor Red
}

Set-Content -Path $file -Value $h -Encoding UTF8 -NoNewline
Write-Host "`
$changes of 3 change(s) applied." -ForegroundColor Cyan
Write-Host ""
Write-Host "NEXT: open index.html and replace YOUR_GOOGLE_SCRIPT_URL with your" -ForegroundColor Yellow
Write-Host "      Apps Script web app URL (see SETUP-BACKEND.md)." -ForegroundColor Yellow
Write-Host ""
Write-Host "Restore:  Copy-Item index.backup4.html index.html -Force" -ForegroundColor DarkGray

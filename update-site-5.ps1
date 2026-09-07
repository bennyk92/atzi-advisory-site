# ============================================================
#  ATZI Advisory - site update, part 5
#   - fixes the garbled characters in the status messages
#   - raises upload limit to 35 MB per file, unlimited total
#   - uploads one file per request (handles large PDFs / Excels)
#  Run from your site folder:
#    powershell -ExecutionPolicy Bypass -File .\update-site-5.ps1
# ============================================================

$file = "index.html"
if (-not (Test-Path $file)) { Write-Host "ERROR: index.html not found." -ForegroundColor Red; exit 1 }
Copy-Item $file "index.backup5.html" -Force
Write-Host "Backup saved as index.backup5.html" -ForegroundColor Yellow

$h = Get-Content $file -Raw -Encoding UTF8
$changes = 0

# --- keep the existing Apps Script URL ---
$url = ''
$m = [regex]::Match($h, "var GOOGLE_SCRIPT_URL = '([^']*)'")
if ($m.Success) { $url = $m.Groups[1].Value }
if ($url -eq '' -or $url -eq 'YOUR_GOOGLE_SCRIPT_URL') {
    Write-Host "  !!  Could not find your Apps Script URL - you will need to paste it in again after this runs." -ForegroundColor Yellow
    $url = 'YOUR_GOOGLE_SCRIPT_URL'
} else {
    Write-Host "  OK  Found your Apps Script URL - it will be preserved" -ForegroundColor Green
}

function Swap([string]$old, [string]$new, [string]$label) {
    if ($script:h.Contains($old)) { $script:h = $script:h.Replace($old, $new); $script:changes++; Write-Host "  OK  $label" -ForegroundColor Green }
    else { Write-Host "  --  $label (not found)" -ForegroundColor DarkGray }
}

Write-Host ""
Write-Host "Applying changes..." -ForegroundColor Cyan

# --- 1. dropzone text + accepted types ---
Swap 'PDF, Word, Excel or images &middot; up to 10 MB per file, 25 MB total' `
     'PDF, Word, Excel, images or ZIP &middot; up to 35 MB per file, no limit on how many' `
     'Upload limits text'

Swap '.pdf,.doc,.docx,.xls,.xlsx,.csv,.jpg,.jpeg,.png,.zip' `
     '.pdf,.doc,.docx,.xls,.xlsx,.xlsm,.csv,.ppt,.pptx,.jpg,.jpeg,.png,.heic,.tif,.tiff,.zip,.txt' `
     'Accepted file types'

# --- 2. replace the submission handler ---
$startMark = '// ============ SUBMISSION HANDLER'
$i = $h.IndexOf($startMark)
if ($i -ge 0) {
    $j = $h.IndexOf('</script>', $i)
    $newJs = @'
// ============ SUBMISSION HANDLER (v2) ============
// Documents upload one request per file, so large files and many of them are fine.
var GOOGLE_SCRIPT_URL = '{URL}';

var msg=document.getElementById('msg');
var picked=[];
var MAX_FILE=35*1024*1024;

var drop=document.getElementById('drop'), input=document.getElementById('files'),
    list=document.getElementById('filelist'), bar=document.getElementById('bar'),
    barFill=bar?bar.querySelector('i'):null;

function human(b){return b<1024?b+' B':b<1048576?(b/1024).toFixed(0)+' KB':(b/1048576).toFixed(1)+' MB'}
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
  var skipped=[];
  Array.prototype.forEach.call(fs,function(f){
    if(f.size>MAX_FILE){skipped.push(f.name);return}
    picked.push(f);
  });
  if(skipped.length){
    alert('These files are over the 35 MB limit and were not added:\n\n'+skipped.join('\n')+
          '\n\nPlease email them to us directly and we will add them to your file.');
  }
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
    r.onload=function(){res(r.result.split(',')[1])};
    r.onerror=rej;
    r.readAsDataURL(f);
  });
}
function post(body){
  return fetch(GOOGLE_SCRIPT_URL,{
    method:'POST',
    headers:{'Content-Type':'text/plain;charset=utf-8'},
    body:JSON.stringify(body)
  }).then(function(r){return r.json()});
}
function setBar(pct){ if(barFill) barFill.style.width=Math.max(0,Math.min(100,pct))+'%' }

var TYPE={'f-borrower':'Application','f-lender':'Lender','f-partner':'Partner'};

document.querySelectorAll('form.pane').forEach(function(form){
  form.addEventListener('submit',function(e){
    e.preventDefault();
    if(!form.checkValidity()){form.reportValidity();return}
    var btn=form.querySelector('button[type=submit]'), original=btn.textContent;
    var isApp=form.id==='f-borrower';
    var files=isApp?picked.slice():[];
    var type=TYPE[form.id]||'Application';

    var fields={};
    new FormData(form).forEach(function(v,k){
      if(['access_key','subject','from_name','botcheck'].indexOf(k)===-1&&v) fields[k]=v;
    });

    btn.disabled=true;
    msg.className='msg';
    if(files.length){ if(bar){bar.classList.add('on');setBar(3)} btn.textContent='Uploading 1 of '+files.length+'...'; }
    else { btn.textContent='Sending...'; }

    var job;
    if(!files.length){
      job=post({action:'submit',formType:type,fields:fields});
    }else{
      var folderId='', folderUrl='', names=[];
      job=post({action:'start',formType:type,fields:fields}).then(function(res){
        if(!res||!res.success) throw new Error('start failed');
        folderId=res.folderId; folderUrl=res.folderUrl;
        var chain=Promise.resolve();
        files.forEach(function(f,i){
          chain=chain.then(function(){
            btn.textContent='Uploading '+(i+1)+' of '+files.length+'...';
            return readFile(f).then(function(b64){
              return post({action:'file',folderId:folderId,fileName:f.name,mimeType:f.type,data:b64});
            }).then(function(r){
              if(!r||!r.success) throw new Error('upload failed: '+f.name);
              names.push(f.name);
              setBar(5+((i+1)/files.length)*88);
            });
          });
        });
        return chain;
      }).then(function(){
        btn.textContent='Finishing...';
        return post({action:'finish',formType:type,fields:fields,folderId:folderId,folderUrl:folderUrl,fileNames:names});
      });
    }

    job.then(function(res){
      if(!res||!res.success) throw new Error((res&&res.error)||'Failed');
      setBar(100);
      msg.className='msg ok';
      msg.textContent='Thank you {EMDASH} your submission has been received'+
        (files.length?' along with '+files.length+' document'+(files.length>1?'s':''):'')+
        '. We review every inquiry personally and will be in touch shortly.';
      form.reset(); picked=[]; render();
      msg.scrollIntoView({behavior:'smooth',block:'center'});
    }).catch(function(err){
      msg.className='msg err';
      msg.innerHTML='Something went wrong sending your submission. Please email us directly at <a href="mailto:info@atziadvisory.com">info@atziadvisory.com</a>.';
      msg.scrollIntoView({behavior:'smooth',block:'center'});
    }).finally(function(){
      btn.disabled=false; btn.textContent=original;
      if(bar) setTimeout(function(){bar.classList.remove('on');setBar(0)},900);
    });
  });
});

'@
    $newJs = $newJs.Replace('{EMDASH}', [string][char]0x2014).Replace('{URL}', $url)
    $h = $h.Substring(0, $i) + $newJs + $h.Substring($j)
    $changes++
    Write-Host "  OK  Submission handler replaced (large-file upload, encoding fixed)" -ForegroundColor Green
} else {
    Write-Host "  --  Submission handler NOT FOUND" -ForegroundColor Red
}

# --- 3. sweep any leftover garbled characters ---
$bad1 = [string][char]0x00E2 + [string][char]0x20AC + [string][char]0x201D  # em dash mojibake
$bad2 = [string][char]0x00E2 + [string][char]0x20AC + [string][char]0x00A6  # ellipsis mojibake
$bad3 = [string][char]0x00E2 + [string][char]0x20AC + [string][char]0x2122  # en dash mojibake
if ($h.Contains($bad1) -or $h.Contains($bad2) -or $h.Contains($bad3)) {
    $h = $h.Replace($bad1, [string][char]0x2014).Replace($bad2, '...').Replace($bad3, [string][char]0x2013)
    Write-Host "  OK  Cleaned up leftover garbled characters" -ForegroundColor Green
    $changes++
} else {
    Write-Host "  OK  No garbled characters remaining" -ForegroundColor Green
}

$utf8 = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText((Join-Path $PWD $file), $h, $utf8)

Write-Host ""
Write-Host "$changes change(s) applied." -ForegroundColor Cyan
Write-Host "IMPORTANT: replace Code.gs in your Apps Script project with the new" -ForegroundColor Yellow
Write-Host "version, then Deploy > Manage deployments > pencil > New version > Deploy." -ForegroundColor Yellow
Write-Host ""
Write-Host "Restore:  Copy-Item index.backup5.html index.html -Force" -ForegroundColor DarkGray

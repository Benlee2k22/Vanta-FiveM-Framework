const app=document.querySelector('#app'),post=(name,data={})=>fetch(`https://${GetParentResourceName()}/${name}`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(data)}).catch(()=>{});
let characters=[],maxSlots=4,deleteId=null,spawnCharacter=null;
function show(id){document.querySelectorAll('.screen').forEach(s=>s.classList.add('hidden'));document.querySelector('#'+id).classList.remove('hidden')}
function esc(v){return String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]))}
function renderCharacters(){
 const grid=document.querySelector('#characterGrid');grid.replaceChildren();document.querySelector('#slotCount').textContent=`${characters.length} / ${maxSlots}`;
 if(!characters.length){const empty=document.createElement('div');empty.className='empty';empty.textContent='No characters yet. Create your first character to get started.';grid.append(empty)}
 characters.forEach(c=>{
  const card=document.createElement('article');card.className='character-card';
  const job=esc(c.job||'Unemployed'),bank=Number(c.bank||0).toLocaleString();
  card.innerHTML=`<div class="card-top"><span class="slot">SLOT ${esc(c.slot)}</span><span class="card-id">${esc(c.citizenid)}</span></div><h2 class="card-name">${esc(c.firstname)} ${esc(c.lastname)}</h2><div class="card-stats"><div><span>OCCUPATION</span>${job}</div><div><span>BANK BALANCE</span>$${bank}</div><div><span>DATE OF BIRTH</span>${esc(c.birthdate)}</div><div><span>NATIONALITY</span>${esc(c.nationality)}</div></div><div class="card-actions"><button class="select-button">Select character →</button><button class="delete-button" aria-label="Delete character">×</button></div>`;
  card.querySelector('.select-button').onclick=()=>{spawnCharacter=c;show('spawnScreen');post('character:spawns',{citizenid:c.citizenid})};
  card.querySelector('.delete-button').onclick=()=>{deleteId=c.citizenid;document.querySelector('#confirm').classList.remove('hidden')};
  grid.append(card)
 });
 document.querySelector('#newCharacter').classList.toggle('hidden',characters.length>=maxSlots)
}
document.querySelector('#newCharacter').onclick=()=>show('createScreen');
document.querySelectorAll('[data-screen]').forEach(b=>b.onclick=()=>show(b.dataset.screen==='list'?'listScreen':b.dataset.screen));
document.querySelector('#createForm').addEventListener('submit',e=>{e.preventDefault();const fd=new FormData(e.currentTarget);post('character:create',{firstname:fd.get('firstname'),lastname:fd.get('lastname'),birthdate:fd.get('birthdate'),nationality:fd.get('nationality'),gender:fd.get('gender')});show('listScreen')});
document.querySelector('#cancelDelete').onclick=()=>{deleteId=null;document.querySelector('#confirm').classList.add('hidden')};
document.querySelector('#confirmDelete').onclick=()=>{if(deleteId)post('character:delete',{citizenid:deleteId});deleteId=null;document.querySelector('#confirm').classList.add('hidden')};
window.addEventListener('message',e=>{
 const m=e.data||{};
 if(m.action==='character:open'){app.classList.remove('hidden');show('listScreen')}
 if(m.action==='character:list'){characters=m.characters||[];maxSlots=Number(m.maxSlots)||4;renderCharacters()}
 if(m.action==='character:spawns'){
  const d=m.data||{};spawnCharacter=d;document.querySelector('#spawnTitle').textContent='Choose your spawn';document.querySelector('#spawnEyebrow').textContent='WELCOME, '+(d.name||'RESIDENT').toUpperCase();
  const grid=document.querySelector('#spawnGrid');grid.replaceChildren();
  if(d.last&&d.last.x){const b=document.createElement('button');b.className='spawn-card';b.innerHTML='<i>↺</i><strong>Last location</strong><p>Return to where you last left this character.</p>';b.onclick=()=>post('character:chooseSpawn',{citizenid:d.citizenid,spawnId:'last'});grid.append(b)}
  Object.entries(d.points||{}).forEach(([id,p])=>{const b=document.createElement('button');b.className='spawn-card';b.innerHTML=`<i>${esc(p.icon||'⌖')}</i><strong>${esc(p.label)}</strong><p>${esc(p.description||'Choose this location.')}</p>`;b.onclick=()=>post('character:chooseSpawn',{citizenid:d.citizenid,spawnId:id});grid.append(b)});
  show('spawnScreen')
 }
});

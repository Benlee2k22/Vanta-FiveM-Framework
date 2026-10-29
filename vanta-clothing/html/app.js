const root=document.querySelector('#clothing'),post=(name,data={})=>fetch(`https://${GetParentResourceName()}/${name}`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(data)}).catch(()=>{});
const componentLabels=['Face','Mask','Hair','Torso','Legs','Bags','Shoes','Accessories','Undershirt','Armour','Decals','Top'];const propLabels=[['Hats',0],['Glasses',1],['Ears',2],['Watches',6],['Bracelets',7]];
let current={components:[],props:[],mode:'shop'},selected={kind:'component',id:11},outfits=[];
function selectedSlot(){const list=selected.kind==='component'?current.components:current.props;return list.find(x=>Number(x.id)===Number(selected.id))}
function render(){
 const slot=selectedSlot();if(!slot)return;
 document.querySelector('#categoryName').textContent=slot.label;document.querySelector('#drawableValue').textContent=slot.drawable<0?'None':slot.drawable;document.querySelector('#textureValue').textContent=slot.texture;document.querySelector('#categoryCount').textContent=`Style ${slot.drawable<0?0:slot.drawable+1}/${slot.maxDrawable+1} · Texture ${slot.texture+1}/${slot.maxTexture+1}`;
 document.querySelectorAll('.category-list button').forEach(b=>b.classList.toggle('active',b.dataset.kind===selected.kind&&Number(b.dataset.id)===Number(selected.id)))
}
function renderCategories(){
 const node=document.querySelector('#categories');node.replaceChildren();
 current.components.forEach(s=>{const b=document.createElement('button');b.textContent=s.label;b.dataset.kind='component';b.dataset.id=s.id;b.onclick=()=>{selected={kind:'component',id:s.id};render()};node.append(b)});
 current.props.forEach(s=>{const b=document.createElement('button');b.textContent=s.label;b.dataset.kind='prop';b.dataset.id=s.id;b.onclick=()=>{selected={kind:'prop',id:s.id};render()};node.append(b)});
}
document.querySelectorAll('.control button').forEach(b=>b.onclick=()=>post('clothing:adjust',{...selected,field:b.dataset.field,delta:Number(b.dataset.delta)}));
document.querySelector('#save').onclick=()=>{const label=document.querySelector('#outfitName').value.trim()||'Saved outfit';post('clothing:save',{label})};
document.querySelector('#close').onclick=()=>{root.classList.add('hidden');post('clothing:close')};
window.addEventListener('keydown',e=>{if(e.key==='Escape'&&!root.classList.contains('hidden')){root.classList.add('hidden');post('clothing:close')}});
window.addEventListener('message',e=>{
 const m=e.data||{};
 if(m.action==='clothing:open'){current=m.state||current;root.classList.remove('hidden');document.querySelector('#modeTitle').textContent=current.mode==='shop'?'CLOTHING STORE':'PERSONAL WARDROBE';document.querySelector('#wardrobe').classList.toggle('hidden',current.mode!=='wardrobe');document.querySelector('#priceNote').textContent=current.mode==='shop'?`$ ${current.price} `:'FREE';renderCategories();render()}
 if(m.action==='clothing:state'){current={...current,...m.state};renderCategories();render()}
 if(m.action==='clothing:outfits'){outfits=m.outfits||[];const list=document.querySelector('#outfitList');list.replaceChildren();if(!outfits.length){const p=document.createElement('small');p.textContent='No saved outfits yet.';list.append(p)}outfits.forEach(o=>{const row=document.createElement('div');row.className='outfit';const name=document.createElement('strong');name.textContent=o.label;const actions=document.createElement('div');const wear=document.createElement('button');wear.textContent='Wear';wear.onclick=()=>post('clothing:wear',{id:o.id});const del=document.createElement('button');del.className='delete';del.textContent='Delete';del.onclick=()=>post('clothing:delete',{id:o.id});actions.append(wear,del);row.append(name,actions);list.append(row)})}
});

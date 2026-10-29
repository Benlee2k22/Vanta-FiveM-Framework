const fill=document.querySelector('#fill'),percent=document.querySelector('#percent'),status=document.querySelector('#status'),tip=document.querySelector('#tip');
const tips=['Tip: Use E at nearby locations to open their options.','Tip: Press F1 for your quick action radial.','Tip: Save outfits at a wardrobe to change back later.','Tip: Your character can choose a spawn point when joining.'];
let tipIndex=0;setInterval(()=>{tipIndex=(tipIndex+1)%tips.length;tip.textContent=tips[tipIndex]},6500);
window.addEventListener('message',event=>{
 const data=event.data||{};
 if(data.eventName==='loadProgress'){const value=Math.max(0,Math.min(1,Number(data.loadFraction)||0));fill.style.width=(value*100)+'%';percent.textContent=Math.round(value*100)+'%';status.textContent=value<.25?'Connecting to Vanta':value<.7?'Loading city resources':'Almost ready'}
 if(data.eventName==='onLogLine'){const line=String(data.message||'').toLowerCase();if(line.includes('starting'))status.textContent='Starting your session';else if(line.includes('loading'))status.textContent='Loading city resources'}
});
let audioContext=null, master=null, playing=false, oscillators=[];
function startMusic(){
 const AudioCtx=window.AudioContext||window.webkitAudioContext;if(!AudioCtx)return;
 if(!audioContext){audioContext=new AudioCtx();master=audioContext.createGain();master.gain.value=Number(document.querySelector('#volume').value)/100*.11;master.connect(audioContext.destination);
  const notes=[110,164.81,220,261.63];notes.forEach((hz,i)=>{const osc=audioContext.createOscillator(),gain=audioContext.createGain();osc.type=i===0?'triangle':'sine';osc.frequency.value=hz;gain.gain.value=i===0?.16:.055;osc.connect(gain);gain.connect(master);osc.start();oscillators.push(osc)});
  const lfo=audioContext.createOscillator(),lfoGain=audioContext.createGain();lfo.frequency.value=.08;lfoGain.gain.value=.025;lfo.connect(lfoGain);lfoGain.connect(master.gain);lfo.start();oscillators.push(lfo);
 }
 audioContext.resume();playing=true;document.querySelector('#music').classList.add('on');document.querySelector('#musicLabel').textContent='Ambient music enabled';document.querySelector('#musicToggle').textContent='ON'
}
function stopMusic(){if(audioContext)audioContext.suspend();playing=false;document.querySelector('#music').classList.remove('on');document.querySelector('#musicLabel').textContent='Enable ambient music';document.querySelector('#musicToggle').textContent='OFF'}
document.querySelector('#music').addEventListener('click',()=>playing?stopMusic():startMusic());
document.querySelector('#volume').addEventListener('input',e=>{if(master)master.gain.value=Number(e.target.value)/100*.11});

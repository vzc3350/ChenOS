#!/usr/bin/env bash
# ChenOS ISO builder: Debian 13 + Chromium kiosk running the ChenOS shell (index.html).
# Single file: it generates the shell (index.html) and helper (launcher.py) itself. Run as root with internet.
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Run as root"; exit 1; }
ARCH="$(dpkg --print-architecture)"
case "$ARCH" in
  amd64) BL="syslinux,grub-efi" ;;
  arm64) BL="grub-efi" ;;
  *) echo "Unsupported arch $ARCH"; exit 1 ;;
esac
apt-get update
apt-get install -y live-build debootstrap squashfs-tools xorriso mtools dosfstools grub-efi-"$ARCH"-bin
if [ "$ARCH" = amd64 ]; then apt-get install -y syslinux syslinux-common syslinux-utils isolinux; fi

WORK=/opt/chenos-build; rm -rf "$WORK"; mkdir -p "$WORK"; cd "$WORK"
lb config --distribution trixie --architectures "$ARCH" \
  --archive-areas "main contrib non-free-firmware" --binary-images iso-hybrid \
  --bootloaders "$BL" --debian-installer none \
  --iso-volume "ChenOS" --iso-application "ChenOS X 10.7" \
  --bootappend-live "boot=live components autologin username=chen quiet splash locales=en_US.UTF-8"

C=config/includes.chroot
mkdir -p config/package-lists $C/opt/chenos $C/etc/skel $C/usr/local/bin \
  $C/etc/chromium/policies/managed $C/usr/share/icons/hicolor/scalable/apps $C/usr/share/applications config/hooks/live

cat > config/package-lists/chenos.list.chroot <<'L'
xserver-xorg
xinit
openbox
x11-xserver-utils
chromium
wine
flatpak
pcmanfm
python3
sudo
network-manager
fonts-inter
fonts-noto-color-emoji
spice-vdagent
qemu-guest-agent
L

cat > $C/opt/chenos/index.html <<'CHENOS_INDEX_EOF'
<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover"><title>ChenOS X 10.7</title><style>
:root{--g:.6;--gl:255,255,255;--tx:#1d1d1f;--sub:#6e6e73;--panel:#f2f2f7;--card:#fff;--sep:rgba(0,0,0,.1);box-sizing:border-box;padding-top:env(safe-area-inset-top,0px);padding-bottom:env(safe-area-inset-bottom,0px);scroll-padding-top:env(safe-area-inset-top,0px)}
@media(prefers-color-scheme:dark){:root:not([data-theme=light]){--gl:44,44,50;--tx:#f5f5f7;--sub:#98989d;--panel:#1c1c1e;--card:#2c2c2e;--sep:rgba(255,255,255,.12)}}
:root[data-theme=dark]{--gl:44,44,50;--tx:#f5f5f7;--sub:#98989d;--panel:#1c1c1e;--card:#2c2c2e;--sep:rgba(255,255,255,.12)}
html{height:100%}body{margin:0;height:100%;background:#111;overflow:hidden;font:13px -apple-system,"Inter","Segoe UI",sans-serif;color:var(--tx)}
#os{position:relative;height:100%;overflow:hidden;user-select:none;-webkit-user-select:none}#wp{position:absolute;inset:0;width:100%;height:100%}
.gd,.gl{-webkit-backdrop-filter:blur(calc(var(--g)*30px)) saturate(1.7);backdrop-filter:blur(calc(var(--g)*30px)) saturate(1.7)}
.gd{background:rgba(28,28,36,calc(.5 - var(--g)*.32));color:#fff;box-shadow:inset 0 0 0 .5px rgba(255,255,255,calc(.15 + var(--g)*.4)),inset 0 1px 0 rgba(255,255,255,calc(var(--g)*.45))}
.gl{background:rgba(var(--gl),calc(.85 - var(--g)*.5));color:var(--tx);box-shadow:inset 0 0 0 .5px rgba(255,255,255,calc(.15 + var(--g)*.4)),inset 0 1px 0 rgba(255,255,255,calc(var(--g)*.6))}
#mb{position:absolute;top:0;left:0;right:0;height:26px;display:flex;align-items:center;gap:14px;padding:0 12px;z-index:900;transition:transform .25s}
.w{cursor:pointer}.fs #mb{transform:translateY(-100%)}.fs #dw{transform:translateY(140%)}
#dw{position:absolute;bottom:8px;left:0;right:0;display:flex;justify-content:center;z-index:800;pointer-events:none;transition:transform .3s}
#dock{pointer-events:auto;display:flex;align-items:flex-end;gap:6px;padding:6px 8px;height:46px;border-radius:22px}
.ic{width:46px;height:46px;border-radius:11px;position:relative;display:grid;place-items:center;color:#fff;font-weight:600;font-size:19px;flex:none;cursor:pointer;transition:width .12s,height .12s,font-size .12s}
.ic i{position:absolute;bottom:-6px;width:4px;height:4px;border-radius:50%;background:#fff;display:none}.ic.on i{display:block}
.win{position:absolute;border-radius:12px;overflow:hidden;box-shadow:0 20px 50px rgba(0,0,0,.35),0 0 0 .5px rgba(0,0,0,.25);display:flex;flex-direction:column;animation:pop .22s cubic-bezier(.2,.9,.3,1.2);transition:transform .3s,opacity .3s,left .3s,top .3s,width .3s,height .3s}
@keyframes pop{from{transform:scale(.85);opacity:0}}.win.drag{transition:none}.win.out{transform:scale(.9);opacity:0}.win.min{transform:scale(.05);opacity:0;pointer-events:none}
.win.full{left:0!important;top:0!important;width:100%!important;height:100%!important;border-radius:0}
.tb{height:38px;display:flex;align-items:center;padding:0 12px;gap:8px;flex:none;position:relative}.tb .t{position:absolute;left:0;right:0;text-align:center;pointer-events:none;font-weight:600}
.l{width:12px;height:12px;border-radius:50%;border:0;padding:0;z-index:1}.bd{flex:1;min-height:0;display:flex;background:var(--panel);user-select:text}
.grp{background:var(--card);border-radius:12px;margin:0 0 18px;overflow:hidden}.row{display:flex;justify-content:space-between;align-items:center;padding:11px 14px;border-bottom:.5px solid var(--sep)}.row:last-child{border:0}
.ni{display:flex;gap:9px;align-items:center;padding:7px 9px;border-radius:9px;margin:2px 6px;cursor:pointer}.ni.on{background:#0a84ff;color:#fff}.ni u{width:24px;height:24px;border-radius:6px;display:grid;place-items:center;color:#fff;text-decoration:none}
.sw{width:44px;height:26px;border-radius:13px;background:#8e8e93;position:relative;cursor:pointer;flex:none}.sw:after{content:"";position:absolute;top:2px;left:2px;width:22px;height:22px;border-radius:50%;background:#fff;transition:.2s}.sw.on{background:#34c759}.sw.on:after{left:20px}
input[type=range]{width:100%;accent-color:#0a84ff}.pv{height:120px;border-radius:14px;position:relative;overflow:hidden;background:linear-gradient(135deg,#ff6a88,#7b2ff7);margin-bottom:16px}.pv i{position:absolute;border-radius:50%}
.pop{position:absolute;top:32px;right:8px;width:290px;max-width:94vw;box-sizing:border-box;border-radius:18px;padding:12px;z-index:950;display:none}
.tl{background:rgba(255,255,255,.14);border-radius:14px;padding:14px 10px;text-align:center;cursor:pointer}.tl.on{background:#0a84ff}.g2{display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-bottom:10px}
#lp{position:absolute;inset:0;z-index:960;display:none;flex-direction:column;align-items:center;padding-top:60px;background:rgba(20,20,30,.35);-webkit-backdrop-filter:blur(calc(10px + var(--g)*30px));backdrop-filter:blur(calc(10px + var(--g)*30px));color:#fff;animation:pop .25s}
#lg{display:grid;grid-template-columns:repeat(auto-fill,90px);gap:26px 18px;justify-content:center;margin-top:34px;width:min(640px,92%)}#lg div{text-align:center;cursor:pointer}#lg .ic{width:64px;height:64px;margin:0 auto 6px;font-size:26px;transition:none}
.mr{padding:6px 12px;border-radius:6px;cursor:pointer}.mr:hover{background:#0a84ff}.ic svg{width:100%;height:100%;display:block;border-radius:23%}.ic{filter:drop-shadow(0 3px 4px rgba(0,0,0,.35))}.ic::before{content:"";position:absolute;left:9%;top:5%;width:82%;height:44%;border-radius:50% 50% 55% 55%/70% 70% 30% 30%;background:linear-gradient(rgba(255,255,255,.7),rgba(255,255,255,.05));pointer-events:none}.ic::after{content:"";position:absolute;inset:0;border-radius:23%;pointer-events:none;background:linear-gradient(165deg,rgba(255,255,255,.28),rgba(255,255,255,0) 45%,rgba(0,0,0,.14));box-shadow:inset 0 1.5px 1px rgba(255,255,255,.95),inset 0 -2.5px 4px rgba(255,255,255,.4),inset 0 0 0 .5px rgba(255,255,255,.55),inset 0 -8px 12px rgba(0,0,0,.15)}@media(max-width:640px){.mi{display:none}}
</style></head><body><div id="os">
<svg id="wp" viewBox="0 0 1000 700" preserveAspectRatio="xMidYMid slice" aria-label="Wallpaper"><defs><linearGradient id="a" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#1b1464"/><stop offset=".5" stop-color="#7b2ff7"/><stop offset="1" stop-color="#ff6a88"/></linearGradient><filter id="bl" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="45"/></filter><radialGradient id="o1" cx=".32" cy=".28" r=".85"><stop offset="0" stop-color="#fff" stop-opacity=".7"/><stop offset=".4" stop-color="#fff" stop-opacity=".1"/><stop offset="1" stop-color="#fff" stop-opacity=".03"/></radialGradient><linearGradient id="rb" x2="1"><stop stop-color="#5ac8fa" stop-opacity=".85"/><stop offset=".5" stop-color="#af52de" stop-opacity=".6"/><stop offset="1" stop-color="#ff6a88" stop-opacity=".85"/></linearGradient></defs><rect width="1000" height="700" fill="url(#a)"/><g filter="url(#bl)"><circle cx="200" cy="180" r="190" fill="#00c6ff" opacity=".7"/><circle cx="820" cy="120" r="170" fill="#ff5ea8" opacity=".7"/><circle cx="560" cy="580" r="230" fill="#ffb347" opacity=".65"/><circle cx="140" cy="600" r="160" fill="#7b2ff7" opacity=".8"/></g><g fill="none" stroke-linecap="round"><path d="M-20 380C180 220 330 520 520 360S850 180 1020 330" stroke="url(#rb)" stroke-width="84" opacity=".55"/><path d="M-20 380C180 220 330 520 520 360S850 180 1020 330" transform="translate(0,-30)" stroke="#fff" stroke-opacity=".4" stroke-width="4"/><path d="M-20 560C200 440 360 650 560 540S880 420 1020 520" stroke="url(#rb)" stroke-width="60" opacity=".5"/><path d="M-20 560C200 440 360 650 560 540S880 420 1020 520" transform="translate(0,-22)" stroke="#fff" stroke-opacity=".35" stroke-width="3"/></g><g stroke="#fff" stroke-opacity=".5" stroke-width="1.5"><circle cx="270" cy="330" r="90" fill="url(#o1)"/><circle cx="760" cy="250" r="60" fill="url(#o1)"/><circle cx="700" cy="500" r="110" fill="url(#o1)"/></g><g fill="none" stroke="#fff" stroke-opacity=".85" stroke-width="5" stroke-linecap="round"><path d="M205 292A75 75 0 0 1 244 260"/><path d="M717 225A50 50 0 0 1 743 203"/><path d="M620 454A92 92 0 0 1 669 414"/></g><text x="500" y="500" text-anchor="middle" font-size="230" font-weight="900" letter-spacing="24" fill="#fff" fill-opacity=".05" font-family="Inter,sans-serif">VZC</text></svg>
<div id="mb" class="gd"><b class="w" id="logo">V</b><b id="an">Desktop</b><span class="mi">File</span><span class="mi">Edit</span><span class="mi">View</span><span class="mi">Window</span><span style="flex:1"></span><span class="w" id="bcl" title="Claude" style="color:#ffb38a;font-size:15px">✦</span><span class="w" id="bcc" title="Control Center"><svg width="16" height="12" viewBox="0 0 16 12"><rect x=".5" y=".5" width="15" height="4.5" rx="2.2" fill="none" stroke="#fff"/><circle cx="12" cy="2.75" r="1.6" fill="#fff"/><rect x=".5" y="7" width="15" height="4.5" rx="2.2" fill="none" stroke="#fff"/><circle cx="4" cy="9.25" r="1.6" fill="#fff"/></svg></span><span title="Battery" style="display:inline-flex;align-items:center;gap:1px"><span style="position:relative;width:27px;height:13px;border-radius:4.5px;background:rgba(255,255,255,.3);overflow:hidden;display:block"><span id="bf" style="position:absolute;left:0;top:0;bottom:0;width:100%;background:#fff"></span><b id="bn" style="position:absolute;inset:0;display:grid;place-items:center;font-size:10px;font-weight:700;color:#1c1c1e">100</b></span><span style="width:2px;height:5px;border-radius:0 2px 2px 0;background:rgba(255,255,255,.45)"></span></span><span id="ck"></span></div>
<div id="cl" class="pop gd"><b style="font-size:15px"><span style="color:#ffb38a">✦</span> Claude</b><p style="color:#c7c7cc;margin:8px 0">Ask anything from the menu bar.</p><form id="cf"><input id="cq" placeholder="Ask Claude" style="width:100%;box-sizing:border-box;border:0;border-radius:10px;padding:9px 12px;background:rgba(255,255,255,.16);color:#fff;outline:0"></form><p id="co" style="margin:10px 0 0;color:#c7c7cc"></p></div>
<div id="am" class="pop gd" style="left:8px;right:auto;width:220px;padding:6px"><div class="mr" data-a="about">About ChenOS</div><div class="mr" data-a="settings">System Settings…</div><div class="mr" data-a="store">App Store…</div><hr style="border:0;border-top:.5px solid rgba(255,255,255,.2);margin:4px 8px"><div class="mr" data-a="lock">Lock Screen</div><div class="mr" data-a="sleep">Sleep</div><div class="mr" data-a="restart">Restart…</div><div class="mr" data-a="shut">Shut Down…</div></div><div id="pw" style="position:absolute;inset:0;background:#000;color:#fff;z-index:3000;display:none;place-items:center;text-align:center"></div><div id="cc" class="pop gd"><div class="g2"><div class="tl on">Wi-Fi</div><div class="tl on">Bluetooth</div><div class="tl" id="tdk">Dark mode</div><div class="tl">Focus</div></div><p style="margin:6px 2px">Display</p><input type="range" id="br" min="30" max="100" value="100"><p style="margin:10px 2px 6px">Sound</p><input type="range" id="vo" min="0" max="100" value="60"><p style="margin:10px 2px 6px">Frosted glass</p><input type="range" id="cg" min="0" max="100" value="60"></div>
<div id="lp"><input id="ls" placeholder="Search" style="width:200px;border:0;border-radius:10px;padding:8px 12px;background:rgba(255,255,255,.2);color:#fff;text-align:center;outline:0"><div id="lg"></div></div>
<div id="dw"><div id="dock" class="gd"></div></div><div id="dim" style="position:absolute;inset:0;background:#000;opacity:0;pointer-events:none;z-index:2000"></div></div>
<script>
const $=s=>document.querySelector(s),R=document.documentElement,OS=$('#os');let wins={},z=10;
const A=[["files","Files"],["launch","Launchpad"],["labrador","Labrador"],["store","App Store"],["music","Music"],["notes","Notes"],["term","Terminal"],["settings","System Settings"]];
const X=[["Mail","mail"],["Photos","photos"],["Maps","maps"],["Clock","clock"],["Calculator","calc"]];
const T={settings:"Settings",labrador:"Labrador",files:"Files",notes:"Notes",term:"Terminal",store:"App Store",music:"Music"};
const setG=v=>R.style.setProperty('--g',v/100),sz=(d,p)=>{d.style.width=d.style.height=p+'px';d.style.fontSize=p*.42+'px'};
const dock=$('#dock');
document.body.insertAdjacentHTML('beforeend',`<svg width="0" height="0" style="position:absolute"><defs>${[["gb","#5ac8fa","#0a84ff"],["gg","#a1a1a6","#636366"],["gr","#ff6b6b","#ff3b30"],["gn","#6be585","#34c759"]].map(([i,a,c])=>`<linearGradient id="${i}" x2="0" y2="1"><stop stop-color="${a}"/><stop offset="1" stop-color="${c}"/></linearGradient>`).join('')}</defs></svg>`);
const IC={files:`<rect width="100" height="100" fill="url(#gb)"/><rect x="18" y="20" width="64" height="60" rx="16" fill="#fff" fill-opacity=".92"/><path d="M50 20v60" stroke="#0a84ff" stroke-width="3"/><circle cx="36" cy="46" r="4" fill="#0a84ff"/><circle cx="64" cy="46" r="4" fill="#0a84ff"/><path d="M34 62q16 12 32 0" stroke="#0a84ff" stroke-width="4" fill="none" stroke-linecap="round"/>`,
launch:`<rect width="100" height="100" fill="url(#gg)"/>${[0,1,2].flatMap(r=>[0,1,2].map(c=>`<rect x="${20+c*22}" y="${20+r*22}" width="16" height="16" rx="4" fill="${['#ff3b30','#ff9500','#ffcc00','#34c759','#5ac8fa','#0a84ff','#af52de','#ff2d55','#fff'][r*3+c]}"/>`)).join('')}`,
labrador:`<rect width="100" height="100" fill="#fff"/><circle cx="50" cy="50" r="30" fill="none" stroke="#ff3b30" stroke-width="7"/><path d="M50 20v60M50 50L29 71M50 50l21 21" stroke="#ff3b30" stroke-width="7" stroke-linecap="round" fill="none"/>`,
store:`<rect width="100" height="100" fill="url(#gb)"/><path d="M50 20L28 78" stroke="#fff" stroke-width="10" stroke-linecap="round"/><path d="M50 20L72 78" stroke="#fff" stroke-width="10" stroke-linecap="round"/><rect x="29" y="54" width="42" height="10" rx="3" fill="#fff"/><path d="M36 54v4M42 54v3M48 54v4M54 54v3M60 54v4M66 54v3" stroke="#0a84ff" stroke-width="1.6" stroke-linecap="round"/>`,
notes:`<rect width="100" height="100" fill="#fff"/><rect width="100" height="28" fill="#ffd60a"/>${[44,58,72].map(y=>`<path d="M16 ${y}h68" stroke="#d1d1d6" stroke-width="3"/>`).join('')}`,
term:`<rect width="100" height="100" fill="#2b2b2e"/><path d="M24 36l18 14-18 14M50 68h26" stroke="#fff" stroke-width="7" stroke-linecap="round" stroke-linejoin="round" fill="none"/>`,
settings:`<rect width="100" height="100" fill="url(#gg)"/><circle cx="50" cy="50" r="24" fill="none" stroke="#f2f2f7" stroke-width="9" stroke-dasharray="7.5 7.5"/><circle cx="50" cy="50" r="17" fill="none" stroke="#f2f2f7" stroke-width="8"/>`,
mail:`<rect width="100" height="100" fill="url(#gb)"/><rect x="18" y="28" width="64" height="44" rx="6" fill="#fff"/><path d="M20 32l30 22 30-22" stroke="#0a84ff" stroke-width="4" fill="none"/>`,
photos:`<rect width="100" height="100" fill="#fff"/>${['#ff3b30','#ff9500','#ffcc00','#34c759','#0a84ff','#af52de'].map((c,i)=>`<circle cx="${50+20*Math.cos(i*1.047)}" cy="${50+20*Math.sin(i*1.047)}" r="14" fill="${c}" fill-opacity=".75"/>`).join('')}`,
music:`<rect width="100" height="100" fill="url(#gr)"/><path d="M42 68V34l26-6v34" stroke="#fff" stroke-width="6" fill="none"/><circle cx="36" cy="68" r="8" fill="#fff"/><circle cx="62" cy="62" r="8" fill="#fff"/>`,
maps:`<rect width="100" height="100" fill="url(#gn)"/><path d="M50 22a18 18 0 0 1 18 18c0 14-18 36-18 36S32 54 32 40a18 18 0 0 1 18-18z" fill="#ff3b30"/><circle cx="50" cy="40" r="6" fill="#fff"/>`,
clock:`<rect width="100" height="100" fill="#1c1c1e"/><circle cx="50" cy="50" r="34" fill="#fff"/><path d="M50 50V28M50 50l14 8" stroke="#1c1c1e" stroke-width="4" stroke-linecap="round"/>`,
calc:`<rect width="100" height="100" fill="#3a3a3c"/>${[0,1,2].flatMap(r=>[0,1,2].map(c=>`<rect x="${18+c*22}" y="${24+r*20}" width="18" height="15" rx="4" fill="${c==2?'#ff9500':'#636366'}"/>`)).join('')}`},ico=k=>`<svg viewBox="0 0 100 100">${IC[k]}</svg>`;
A.forEach(([id,n])=>{const d=document.createElement('div');d.className='ic';d.id='d-'+id;d.title=n;d.innerHTML=ico(id)+'<i></i>';d.onclick=()=>openApp(id);dock.append(d)});
function mag(x){const r=dock.getBoundingClientRect(),cx=r.left+r.width/2,n=A.length;[...dock.children].forEach((d,i)=>{const dd=Math.abs(x-(cx+(i-(n-1)/2)*52)),s=x==null?1:1+.9*Math.max(0,1-dd/130)**2;sz(d,46*s)})}
dock.onpointermove=e=>e.pointerType!='touch'&&mag(e.clientX);dock.onpointerleave=()=>mag(null);
const lg=$('#lg');function addLP(n,s){const d=document.createElement('div');d.innerHTML=`<div class="ic">${s}</div>${n}`;d.onclick=()=>{const a=A.find(x=>x[1]==n);a?openApp(a[0]):closeAll()};lg.append(d)}
A.filter(a=>a[0]!='launch').forEach(a=>addLP(a[1],ico(a[0])));X.forEach(x=>addLP(x[0],ico(x[1])));
$('#ls').oninput=e=>[...lg.children].forEach(c=>c.style.display=c.textContent.toLowerCase().includes(e.target.value.toLowerCase())?'':'none');
function closeAll(){['#cc','#cl','#am'].forEach(s=>$(s).style.display='none');$('#lp').style.display='none'}
function pop(s){const o=$(s).style.display=='block';closeAll();if(!o)$(s).style.display='block'}
function lp(){const s=$('#lp').style.display!='flex';closeAll();if(s)$('#lp').style.display='flex'}
$('#bcc').onclick=()=>pop('#cc');$('#bcl').onclick=()=>pop('#cl');$('#logo').onclick=()=>pop('#am');
const H=p=>fetch('http://127.0.0.1:7777'+p).catch(()=>{}),pw=$('#pw');
const scr=m=>{pw.innerHTML=`<div>${m}</div>`;pw.style.display='grid';pw.onclick=()=>{pw.style.display='none'}};
function act(a){closeAll();if(a=='about'||a=='settings')openApp('settings');else if(a=='store')openApp('store');else if(a=='lock')scr('Locked. Click to unlock.');else if(a=='sleep')scr('');else if(a=='restart'){scr('Restarting…');H('/run?app=reboot');setTimeout(()=>location.reload(),1800)}else{scr('ChenOS is shut down.<br>Click to power on.');H('/run?app=poweroff')}}
document.querySelectorAll('.mr').forEach(r=>r.onclick=()=>act(r.dataset.a));
const tt=document.createElement('div');tt.className='gd';tt.style.cssText='position:absolute;top:34px;left:50%;transform:translateX(-50%);padding:8px 14px;border-radius:12px;z-index:990;display:none;white-space:nowrap';OS.append(tt);
const toast=m=>{tt.textContent=m;tt.style.display='block';clearTimeout(tt._t);tt._t=setTimeout(()=>tt.style.display='none',2600)};
const tile=(n,c)=>`<svg viewBox="0 0 100 100"><rect width="100" height="100" fill="${c}"/><text x="50" y="66" text-anchor="middle" font-size="48" font-weight="700" fill="#fff" font-family="sans-serif">${n[0].toUpperCase()}</text></svg>`;
function inst(f){const e=f.name.split('.').pop().toLowerCase(),k={apk:'Android app',exe:'Windows app',msi:'Windows app',appimage:'Linux app',deb:'Linux app',app:'macOS-style app'}[e];if(!k)return toast('ChenOS can’t open .'+e+' files');toast(`Installing ${f.name} (${k})…`);setTimeout(()=>{addLP(f.name.replace(/\.[^.]+$/,''),tile(f.name,'#636366'));toast('Added to Launchpad')},1200)}
OS.ondragover=e=>e.preventDefault();OS.ondrop=e=>{e.preventDefault();[...e.dataTransfer.files].forEach(inst)};
document.addEventListener('pointerdown',e=>{if(!e.target.closest('.pop,.w,#lg,#ls'))closeAll()});
$('#lp').onclick=e=>{if(e.target.id=='lp')closeAll()};
document.addEventListener('keydown',e=>{if(e.key=='Escape'){closeAll();Object.values(wins).forEach(w=>w.classList.contains('full')&&w.querySelectorAll('.l')[2].click())}});
$('#cf').onsubmit=e=>{e.preventDefault();$('#co').textContent='Preview only: Claude isn’t connected in this demo.'};
$('#br').oninput=e=>$('#dim').style.opacity=(100-e.target.value)/100*.6;
$('#cg').oninput=e=>setG(e.target.value);
const dark=()=>{const d=R.dataset.theme=='dark'||(!R.dataset.theme&&matchMedia('(prefers-color-scheme:dark)').matches);R.dataset.theme=d?'light':'dark';$('#tdk').classList.toggle('on',!d)};
$('#tdk').onclick=dark;document.querySelectorAll('.tl:not(#tdk)').forEach(t=>t.onclick=()=>t.classList.toggle('on'));
const clk=()=>$('#ck').textContent=new Date().toLocaleString('en-US',{weekday:'short',hour:'numeric',minute:'2-digit'});clk();setInterval(clk,30000);navigator.getBattery&&navigator.getBattery().then(b=>{const u=()=>{const p=Math.round(b.level*100);$('#bf').style.width=p+'%';$('#bn').textContent=p;$('#bf').style.background=p<=20?'#ff3b30':b.charging?'#34c759':'#fff'};u();b.onlevelchange=b.onchargingchange=u});
function dot(id){$('#d-'+id).classList.toggle('on',!!wins[id])}
function foc(w){w.classList.remove('min');w.style.zIndex=++z;$('#an').textContent=w.querySelector('.t').textContent}
function openApp(id){if(id=='launch')return lp();closeAll();let w=wins[id];if(w)return foc(w);w=wins[id]=mk(id)}
function mk(id){const w=document.createElement('div'),n=Object.keys(wins).length;w.className='win gl';w.style.cssText=`left:${60+n*32}px;top:${50+n*28}px;width:min(740px,92%);height:min(470px,68%)`;
w.innerHTML=`<div class="tb"><button class="l" style="background:#ff5f57"></button><button class="l" style="background:#febc2e"></button><button class="l" style="background:#28c840"></button><span class="t">${T[id]}</span></div><div class="bd"></div>`;
const [c,m,f]=w.querySelectorAll('.l'),tb=w.querySelector('.tb');
c.onclick=()=>{w.classList.add('out');delete wins[id];dot(id);OS.classList.remove('fs');$('#an').textContent='Desktop';setTimeout(()=>w.remove(),250)};
m.onclick=()=>{const r=$('#d-'+id).getBoundingClientRect(),o=w.getBoundingClientRect();w.style.transformOrigin=`${r.left+r.width/2-o.left}px ${r.top-o.top}px`;w.classList.add('min')};
f.onclick=()=>{w.classList.toggle('full');OS.classList.toggle('fs',w.classList.contains('full'))};
w.onpointerdown=()=>foc(w);
tb.onpointerdown=e=>{if(e.target.tagName=='BUTTON'||w.classList.contains('full'))return;const ox=e.clientX-w.offsetLeft,oy=e.clientY-w.offsetTop;w.classList.add('drag');tb.setPointerCapture(e.pointerId);tb.onpointermove=v=>{w.style.left=v.clientX-ox+'px';w.style.top=Math.max(26,v.clientY-oy)+'px'};tb.onpointerup=()=>{w.classList.remove('drag');tb.onpointermove=null}};
OS.append(w);const b=w.querySelector('.bd');({settings:ST2,labrador:LB,files:FL,notes:NT,term:TM,store:SM2,music:MU})[id](b);foc(w);dot(id);return w}
const SA=[["Firefox","org.mozilla.firefox","#ff7139"],["VLC","org.videolan.VLC","#ff8800"],["Spotify","com.spotify.Client","#1db954"],["Discord","com.discordapp.Discord","#5865f2"],["Steam","com.valvesoftware.Steam","#1b2838"],["VS Code","com.visualstudio.code","#0078d4"],["GIMP","org.gimp.GIMP","#7a6a53"],["OBS Studio","com.obsproject.Studio","#302e31"],["LibreOffice","org.libreoffice.LibreOffice","#18a303"],["Telegram","org.telegram.desktop","#2aabee"],["Slack","com.slack.Slack","#4a154b"],["Zoom","us.zoom.Zoom","#2d8cff"],["Blender","org.blender.Blender","#ea7600"],["Audacity","org.audacityteam.Audacity","#0000cc"],["Thunderbird","org.mozilla.Thunderbird","#0a84ff"],["Kdenlive","org.kde.kdenlive","#2e86de"]];
function SM(b){b.style.flexDirection='column';b.innerHTML=`<div style="padding:14px 18px;display:flex;justify-content:space-between;align-items:center"><b style="font-size:20px">Popular apps</b><label style="color:#0a84ff;cursor:pointer">Install from file…<input type="file" accept=".apk,.exe,.msi,.AppImage,.deb,.app" multiple hidden></label></div><div style="flex:1;overflow:auto;padding:0 18px 18px;display:grid;grid-template-columns:repeat(auto-fill,minmax(200px,1fr));gap:10px;align-content:start">${SA.map(([n,id,c],i)=>`<div class="grp" style="margin:0;padding:12px;display:flex;gap:10px;align-items:center"><div class="ic" style="width:44px;height:44px;cursor:default">${tile(n,c)}</div><div style="flex:1;min-width:0"><div style="font-weight:600">${n}</div><div style="color:var(--sub);font-size:11px">Free</div></div><button data-i="${i}" style="border:0;border-radius:14px;padding:4px 14px;background:#0a84ff;color:#fff;cursor:pointer">Get</button></div>`).join('')}</div>`;
b.querySelectorAll('button').forEach(x=>x.onclick=()=>{const [n,id,c]=SA[x.dataset.i];if(x.textContent=='Open')return toast(n+' opened');x.textContent='Installing…';H('/install?id='+id);setTimeout(()=>{x.textContent='Open';addLP(n,tile(n,c));toast(n+' installed')},1500)});
b.querySelector('input[type=file]').onchange=e=>[...e.target.files].forEach(inst)}
const P={"Wi-Fi":"Wi-Fi:t1|Network:vChenOS-Net|Auto-join:t1|Ask to join networks:t1","Bluetooth":"Bluetooth:t1|Devices:vNone connected","Network":"VPN:t0|Firewall:t0|Proxy:vOff|DNS:vAutomatic","Battery":"Battery level:v100%|Low power mode:t0|Show percentage:t1|Optimized charging:t1","General":"Name:vChenOS|Software Version:vChenOS X 10.7|Browser:vLabrador|Engine:vChromium|Model:vChenOS Virtual Machine;AirDrop:oContacts/Everyone/Off|Autofill:t1|Background App Refresh:t1","Appearance":"Dark mode:t0|Accent color:oBlue/Purple/Pink/Red/Orange/Green|Show scroll bars:oAutomatic/Always|Reduce transparency:t0","Accessibility":"VoiceOver:t0|Zoom:t0|Display zoom:t0|Increase contrast:t0|Reduce motion:t0|Larger text:s40|Voice control:t0|Captions:t0|Switch control:t0|Sticky keys:t0","Control Center":"Show in menu bar:t1|Wi-Fi:t1|Bluetooth:t1|Focus:t1|Sound:t1|Display:t1|Now playing:t0","Siri & Claude":"Ask Claude:t1|Show in menu bar:t1|Voice:oDefault/Warm/Bright|Language:vEnglish","Desktop & Dock":"Size:s46|Magnification:t1|Magnification size:s85|Position:oBottom/Left/Right|Minimize effect:oScale/Genie|Show recents:t1|Hot corners:t0","Displays":"Brightness:s100|Night Shift:t0|True Tone:t1;Resolution:oDefault/Larger text/More space|Refresh rate:oAuto/60 Hz/120 Hz","Wallpaper":"Style:oChenOS Aurora/Dynamic/Color|Show on all spaces:t1","Screen Saver":"Start after:oNever/5 min/10 min|Show clock:t1","Notifications":"Allow notifications:t1|Show previews:oAlways/Unlocked/Never|Do not disturb:t0|Badges:t1|Sounds:t1","Sound":"Volume:s60|Output:vBuilt-in speakers|Input:vMicrophone;Alert sounds:t1|Play feedback:t1","Focus":"Do Not Disturb:t0|Sleep:t0|Work:t0|Personal:t0;Share across devices:t1","Screen Time":"Screen Time:t0|App limits:t0|Downtime:t0|Content restrictions:t0","Lock Screen":"Require password:oImmediately/5 min/1 hr|Show notifications:t1|Show user name:t1","Privacy & Security":"Location services:t1|Camera:t1|Microphone:t1|Analytics:t0|Firewall:t1|FileVault:t0","Passwords":"AutoFill passwords:t1|Security recommendations:t1|Verification codes:t1","Users & Groups":"Current user:vChen|Administrator:vYes;Guest user:t0|Auto login:t1","Keyboard":"Key repeat:s70|Delay until repeat:s40;Press fn key:oShow emoji/Dictation/Nothing|Auto-capitalization:t1|Spelling correction:t1|Dictation:t0","Trackpad & Mouse":"Tap to click:t1|Natural scrolling:t1|Tracking speed:s50|Secondary click:oTwo fingers/Corner|Look up:t1|Swipe between pages:t1","Printers & Scanners":"Printers:vNone added|Scanners:vNone added","Date & Time":"Set automatically:t1|24-hour time:t0|Time zone:vAutomatic","Language & Region":"Language:vEnglish|Region:vUnited States|Units:oMetric/Imperial|First day of week:oSunday/Monday","Storage":"Used:v12 GB of 64 GB|Optimize storage:t1|Empty trash automatically:t0","Software Update":"Automatic updates:t1|Version:vChenOS X 10.7|Status:vUp to date","Frosted Glass":"Liquid glass:s60|Reduce transparency:t0"};
const G1='<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3c3 3 3 15 0 18M12 3c-3 3-3 15 0 18"/>',MO='<path d="M20 14A8 8 0 0 1 10 4a8 8 0 1 0 10 10z"/>';
const SI={"Wi-Fi":["#0a84ff",'<path d="M3 9a13 13 0 0 1 18 0M6 12.5a8.5 8.5 0 0 1 12 0M9 16a4 4 0 0 1 6 0"/><circle cx="12" cy="19" r=".8"/>'],"Bluetooth":["#0a84ff",'<path d="M7 7l10 10-5 4V3l5 4L7 17"/>'],"Network":["#0a84ff",G1],"Battery":["#34c759",'<rect x="3" y="8" width="16" height="9" rx="2"/><path d="M21 11v3"/>'],"General":["#8e8e93",'<circle cx="12" cy="12" r="3"/><circle cx="12" cy="12" r="8" stroke-dasharray="3 3"/>'],"Appearance":["#1c1c1e",'<circle cx="12" cy="12" r="8"/><path d="M12 4a8 8 0 0 1 0 16z" fill="#fff"/>'],"Accessibility":["#0a84ff",'<circle cx="12" cy="5" r="1.6"/><path d="M5 9l7 1.5L19 9M12 10.5V16m0 0l-3 5m3-5l3 5"/>'],"Control Center":["#8e8e93",'<rect x="3" y="5" width="18" height="5" rx="2.5"/><circle cx="16" cy="7.5" r="1.2" fill="#fff"/><rect x="3" y="14" width="18" height="5" rx="2.5"/><circle cx="8" cy="16.5" r="1.2" fill="#fff"/>'],"Siri & Claude":["#af52de",'<path d="M12 3l2 6 6 2-6 2-2 6-2-6-6-2 6-2z"/>'],"Desktop & Dock":["#0a84ff",'<rect x="3" y="4" width="18" height="12" rx="2"/><rect x="7" y="18" width="10" height="2.5" rx="1.2"/>'],"Displays":["#0a84ff",'<circle cx="12" cy="12" r="4"/><path d="M12 3v2M12 19v2M3 12h2M19 12h2M5.6 5.6L7 7M17 17l1.4 1.4M5.6 18.4L7 17M17 7l1.4-1.4"/>'],"Wallpaper":["#32ade6",'<rect x="3" y="4" width="18" height="16" rx="2"/><path d="M3 16l5-5 4 4 3-3 6 6"/>'],"Screen Saver":["#32ade6",'<rect x="3" y="4" width="18" height="12" rx="2"/><path d="M8 20h8"/>'],"Notifications":["#ff3b30",'<path d="M6 16V11a6 6 0 0 1 12 0v5l2 2H4zM10 20a2 2 0 0 0 4 0"/>'],"Sound":["#ff2d55",'<path d="M4 9h4l5-4v14l-5-4H4zM16 9a4 4 0 0 1 0 6M18.5 6.5a8 8 0 0 1 0 11"/>'],"Focus":["#5e5ce6",MO],"Screen Time":["#5e5ce6",'<path d="M7 3h10M7 21h10M8 3v4l4 5-4 5v4M16 3v4l-4 5 4 5v4"/>'],"Lock Screen":["#1c1c1e",'<rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>'],"Privacy & Security":["#0a84ff",'<path d="M12 3l8 3v6c0 5-4 8-8 9-4-1-8-4-8-9V6z"/>'],"Passwords":["#8e8e93",'<circle cx="8" cy="15" r="4"/><path d="M11 12l9-9M16 7l3 3"/>'],"Users & Groups":["#0a84ff",'<circle cx="9" cy="8" r="3"/><path d="M3 20a6 6 0 0 1 12 0"/><circle cx="17" cy="9" r="2.4"/><path d="M16.5 14a5 5 0 0 1 5 5"/>'],"Keyboard":["#8e8e93",'<rect x="2" y="6" width="20" height="12" rx="2"/><path d="M6 10h.1M10 10h.1M14 10h.1M18 10h.1M7 14h10"/>'],"Trackpad & Mouse":["#8e8e93",'<rect x="5" y="3" width="14" height="18" rx="7"/><path d="M12 3v7"/>'],"Printers & Scanners":["#8e8e93",'<path d="M7 9V3h10v6M7 17H4v-7h16v7h-3"/><rect x="7" y="14" width="10" height="7"/>'],"Date & Time":["#0a84ff",'<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>'],"Language & Region":["#0a84ff",G1],"Storage":["#8e8e93",'<rect x="3" y="7" width="18" height="10" rx="2"/><path d="M7 12h.1"/>'],"Software Update":["#8e8e93",'<path d="M20 12a8 8 0 1 1-3-6.2M20 4v5h-5"/>'],"Frosted Glass":["#5ac8fa",'<path d="M12 3c4 5 6 8 6 11a6 6 0 0 1-12 0c0-3 2-6 6-11z"/>']};
function ST2(b){const N=Object.keys(P);let cur='General';
const row=r=>{const i=r.indexOf(':'),l=r.slice(0,i),t=r[i+1],v=r.slice(i+2);return `<div class="row" data-l="${l}"><span>${l}</span>${t=='t'?`<div class="sw ${v=='1'?'on':''}"></div>`:t=='v'?`<span style="color:var(--sub)">${v}</span>`:t=='s'?`<input type="range" style="width:45%" value="${v}">`:`<select>${v.split('/').map(o=>`<option>${o}</option>`).join('')}</select>`}</div>`};
const render=()=>{b.innerHTML=`<div style="display:flex;width:100%;min-height:0"><nav class="gl" style="width:170px;padding:8px 4px;flex:none;overflow:auto">${N.map((p,i)=>`<div class="ni ${p==cur?'on':''}" data-p="${p}"><u style="background:${SI[p][0]}"><svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="#fff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${SI[p][1]}</svg></u>${p}</div>`).join('')}</nav><section style="flex:1;padding:20px;overflow:auto"><h2 style="margin:0 0 14px;font-size:22px">${cur}</h2>${P[cur].split(';').map(g=>`<div class="grp">${g.split('|').map(row).join('')}</div>`).join('')}</section></div>`;
b.querySelectorAll('.ni').forEach(n=>n.onclick=()=>{cur=n.dataset.p;render()});
b.querySelectorAll('.sw').forEach(s=>s.onclick=()=>{s.classList.toggle('on');if(s.parentNode.dataset.l=='Dark mode')dark()});
b.querySelectorAll('input[type=range]').forEach(s=>{const l=s.parentNode.dataset.l;if(l=='Liquid glass')s.value=Math.round(getComputedStyle(R).getPropertyValue('--g')*100);if(l=='Brightness')s.value=$('#br').value;s.oninput=()=>{if(l=='Liquid glass'){setG(s.value);$('#cg').value=s.value}if(l=='Brightness'){$('#br').value=s.value;$('#br').oninput({target:s})}}});
const d=b.querySelector('[data-l="Dark mode"] .sw');if(d&&(R.dataset.theme=='dark'||(!R.dataset.theme&&matchMedia('(prefers-color-scheme:dark)').matches)))d.classList.add('on')};render()}
const SX=[["Minecraft Launcher","com.mojang.Minecraft","#62b47a"],["RetroArch","org.libretro.RetroArch","#3a3a4a"],["Heroic Games","com.heroicgameslauncher.hgl","#4a5568"],["Bitwarden","com.bitwarden.desktop","#175ddc"],["Obsidian","md.obsidian.Obsidian","#7c3aed"],["Brave","com.brave.Browser","#fb542b"]],SB=[...SA,...SX];
const SC={Discover:null,Create:["GIMP","OBS Studio","Blender","Audacity","Kdenlive"],Work:["LibreOffice","Slack","Zoom","Thunderbird","Bitwarden","Obsidian"],Play:["Steam","Discord","Spotify","VLC","Minecraft Launcher","RetroArch","Heroic Games"],Develop:["VS Code","Firefox","Brave"],Updates:[]},INS=new Set();
function SM2(b){let cur='Discover',q='';
const card=([n,id,c])=>`<div class="grp" style="margin:0;padding:12px;display:flex;gap:10px;align-items:center"><div class="ic" style="width:44px;height:44px;cursor:default;flex:none">${tile(n,c)}</div><div style="flex:1;min-width:0"><div style="font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${n}</div><div style="color:var(--sub);font-size:11px">Free</div></div><button data-n="${n}" style="border:0;border-radius:14px;padding:4px 14px;background:#0a84ff;color:#fff;cursor:pointer">${INS.has(n)?'Open':'Get'}</button></div>`;
const list=()=>q?SB.filter(a=>a[0].toLowerCase().includes(q.toLowerCase())):cur=='Discover'?SB:cur=='Updates'?SB.filter(a=>INS.has(a[0])):SB.filter(a=>SC[cur].includes(a[0]));
const render=()=>{const L=list();b.innerHTML=`<div style="display:flex;width:100%;min-height:0"><nav class="gl" style="width:160px;padding:10px 6px;flex:none;overflow:auto"><input id="sq" placeholder="Search" value="${q}" style="width:100%;box-sizing:border-box;border:0;border-radius:8px;padding:6px 8px;margin-bottom:8px;background:rgba(128,128,128,.2);color:var(--tx);outline:0">${Object.keys(SC).map(s=>`<div class="ni ${!q&&s==cur?'on':''}" data-s="${s}">${s}</div>`).join('')}</nav><section style="flex:1;overflow:auto;padding:18px"><div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:12px"><b style="font-size:22px">${q?'Results':cur}</b><label style="color:#0a84ff;cursor:pointer">Install from file…<input type="file" accept=".apk,.exe,.msi,.AppImage,.deb,.app" multiple hidden></label></div>${cur=='Discover'&&!q?`<div style="border-radius:16px;padding:20px;margin-bottom:14px;color:#fff;background:linear-gradient(135deg,#5ac8fa,#af52de,#ff6a88)"><div style="opacity:.8;font-size:11px">FEATURED</div><div style="font-size:22px;font-weight:700">Create anything</div><div>Blender, GIMP, OBS Studio and more</div></div>`:''}<div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(200px,1fr));gap:10px;align-content:start">${L.map(card).join('')||'<span style="color:var(--sub)">Nothing here yet</span>'}</div></section></div>`;
const s=b.querySelector('#sq');s.oninput=()=>{q=s.value;render();const n=b.querySelector('#sq');n.focus();n.setSelectionRange(q.length,q.length)};
b.querySelectorAll('.ni').forEach(n=>n.onclick=()=>{cur=n.dataset.s;q='';render()});
b.querySelectorAll('button[data-n]').forEach(x=>x.onclick=()=>{const [n,id,c]=SB.find(a=>a[0]==x.dataset.n);if(INS.has(n))return toast(n+' opened');x.textContent='Installing…';H('/install?id='+id);setTimeout(()=>{INS.add(n);addLP(n,tile(n,c));toast(n+' installed');x.textContent='Open'},1500)});
b.querySelector('input[type=file]').onchange=e=>[...e.target.files].forEach(inst)};render()}
const TR=[["Glass Morning","ChenOS Sessions",100,[72,76,79,83,79,76,72,67],"#5ac8fa"],["Frosted","ChenOS Sessions",84,[69,72,76,81,76,72,69,64],"#af52de"],["Liquid Light","ChenOS Sessions",112,[67,71,74,79,78,74,71,66],"#ff6a88"],["Peace Sign","Labrador",92,[60,64,67,72,67,64,60,55],"#ff3b30"],["VZC","Hidden Track",120,[74,77,81,86,81,77,74,69],"#ffb340"]];
let AC,mi=0,mp=false,ms=0,mt;
const midi=n=>440*2**((n-69)/12);
function mnote(f,d){const o=AC.createOscillator(),g=AC.createGain(),t=AC.currentTime;o.type='triangle';o.frequency.value=f;o.connect(g);g.connect(AC.destination);g.gain.setValueAtTime(0,t);g.gain.linearRampToValueAtTime(+($('#vo').value)/100*.25,t+.02);g.gain.exponentialRampToValueAtTime(.001,t+d);o.start(t);o.stop(t+d)}
function mtick(){const N=TR[mi][3];mnote(midi(N[ms%N.length]),.5);if(ms%4==0)mnote(midi(N[0]-12),.9);ms++;mui();if(ms>=32)mgo(1)}
function mplay(){AC=AC||new(window.AudioContext||window.webkitAudioContext)();AC.resume&&AC.resume();mp=true;clearInterval(mt);mt=setInterval(mtick,30000/TR[mi][2]);mui()}
function mpause(){mp=false;clearInterval(mt);mui()}
function mgo(d){mi=(mi+d+TR.length)%TR.length;ms=0;if(mp)mplay();else mui()}
function mui(){const t=TR[mi];if(!$('#mt'))return;$('#mt').textContent=t[0];$('#ma').textContent=t[1];$('#mpp').textContent=mp?'❚❚':'▶';$('#mbar').style.width=ms/32*100+'%';$('#mart').style.background=`linear-gradient(135deg,${t[4]},#1c1c1e)`;document.querySelectorAll('.mrow').forEach((r,i)=>r.style.background=i==mi?'rgba(10,132,255,.18)':'')}
function MU(b){b.innerHTML=`<div style="display:flex;width:100%;min-height:0"><nav class="gl" style="width:150px;padding:10px 6px;flex:none"><div class="ni on">Listen Now</div><div class="ni">Library</div><div class="ni">Radio</div></nav><section style="flex:1;overflow:auto;padding:18px"><div style="display:flex;gap:16px;align-items:center;margin-bottom:16px"><div id="mart" style="width:110px;height:110px;border-radius:14px;flex:none;display:grid;place-items:center;color:#fff;font-size:44px;box-shadow:0 8px 20px rgba(0,0,0,.3)">♪</div><div style="flex:1;min-width:0"><div id="mt" style="font-size:20px;font-weight:700"></div><div id="ma" style="color:var(--sub);margin-bottom:10px"></div><div style="height:4px;border-radius:2px;background:var(--sep);overflow:hidden"><div id="mbar" style="height:100%;background:#ff2d55;width:0"></div></div><div style="display:flex;gap:22px;font-size:20px;margin-top:10px;cursor:pointer"><span id="mpv">⏮</span><span id="mpp">▶</span><span id="mnx">⏭</span></div></div></div><div class="grp">${TR.map((t,i)=>`<div class="row mrow" data-i="${i}" style="cursor:pointer"><span>${t[0]}</span><span style="color:var(--sub)">${t[1]}</span></div>`).join('')}</div></section></div>`;
$('#mpv').onclick=()=>mgo(-1);$('#mnx').onclick=()=>mgo(1);$('#mpp').onclick=()=>mp?mpause():mplay();
b.querySelectorAll('.mrow').forEach(r=>r.onclick=()=>{mi=+r.dataset.i;ms=0;mplay()});mui()}
function FL(b){b.innerHTML=`<div style="padding:18px;display:grid;grid-template-columns:repeat(auto-fill,90px);gap:14px;align-content:start;width:100%">${["Documents","Downloads","Pictures","Music","Apps"].map(n=>`<div style="text-align:center"><div style="width:64px;height:48px;margin:auto;border-radius:8px;background:#5ac8fa"></div><div style="margin-top:6px">${n}</div></div>`).join('')}</div>`}
function NT(b){b.innerHTML='<textarea placeholder="Start typing" style="flex:1;border:0;padding:16px;font:15px inherit;background:var(--panel);color:var(--tx);outline:0;resize:none"></textarea>'}
function TM(b){b.style.background='#14141c';b.innerHTML='<pre style="margin:0;padding:16px;color:#7ee787;font:13px ui-monospace,monospace;line-height:1.6">$ chenos --info\nChenOS X 10.7\nBrowser: Labrador\nShell: Glass 1.0\n$ _</pre>'}
function LB(b){b.innerHTML=`<div style="display:flex;flex-direction:column;width:100%"><div class="gl" style="display:flex;gap:4px;padding:4px 10px 0;align-items:flex-end"><div style="background:var(--panel);padding:7px 14px;border-radius:9px 9px 0 0;font-size:12px">New tab ×</div><div style="padding:7px 10px">+</div></div><div style="display:flex;gap:12px;align-items:center;padding:7px 10px;border-bottom:.5px solid var(--sep)"><span>←</span><span>→</span><span>⟳</span><form id="uf" style="flex:1"><input id="u" placeholder="Search or enter address" style="width:100%;box-sizing:border-box;border:0;border-radius:16px;padding:7px 14px;background:var(--card);color:var(--tx);outline:0"></form></div><div id="pg" style="flex:1;display:grid;place-items:center;text-align:center;padding:20px"><div><div style="font-size:38px;font-weight:700">Labrador</div><p style="color:var(--sub)">Chromium engine, ChenOS skin.</p></div></div></div>`;
b.querySelector('#uf').onsubmit=e=>{e.preventDefault();const p=b.querySelector('#pg'),q=b.querySelector('#u').value;p.innerHTML='<div><p style="font-weight:600;margin:0 0 6px"></p><p style="color:var(--sub);margin:0">Pages load in the real ChenOS build, which runs Chromium.</p></div>';p.querySelector('p').textContent=q}}
function ST(b){const P=["General","Appearance","Frosted Glass"],C=["#8e8e93","#0a84ff","#5e5ce6"],G=["⚙","◐","◈"];let cur=0;
const sw=()=>R.dataset.theme=='dark'||(!R.dataset.theme&&matchMedia('(prefers-color-scheme:dark)').matches);
const pages=[()=>`<div class="grp">${[["Name","ChenOS"],["Software Version","ChenOS X 10.7"],["Browser","Labrador"],["Engine","Chromium"],["Model","ChenOS Virtual Machine"]].map(([k,v])=>`<div class="row"><span>${k}</span><span style="color:var(--sub)">${v}</span></div>`).join('')}</div>`,
()=>`<div class="grp"><div class="row"><span>Dark mode</span><div class="sw ${sw()?'on':''}" id="ds"></div></div></div>`,
()=>`<div class="pv"><i style="width:90px;height:90px;background:#ffd36e;left:30px;top:-20px"></i><i style="width:110px;height:110px;background:#4da3ff;right:20px;bottom:-30px"></i><div class="gl" style="position:absolute;inset:28px 50px;border-radius:18px;display:grid;place-items:center;font-weight:600">Frosted glass</div></div><div class="grp" style="padding:14px"><div class="row" style="padding:0 0 8px;border:0"><span>Liquid glass</span><span id="gv" style="color:var(--sub)"></span></div><input type="range" id="gs" min="0" max="100"><div class="row" style="padding:6px 0 0;border:0;color:var(--sub);font-size:11px"><span>Clear</span><span>Frosted</span></div></div>`];
function render(){b.innerHTML=`<div style="display:flex;width:100%"><nav class="gl" style="width:170px;padding:10px 4px;flex:none">${P.map((p,i)=>`<div class="ni ${i==cur?'on':''}" data-i="${i}"><u style="background:${C[i]}">${G[i]}</u>${p}</div>`).join('')}</nav><section style="flex:1;padding:20px;overflow:auto"><h2 style="margin:0 0 14px;font-size:22px">${P[cur]}</h2>${pages[cur]()}</section></div>`;
b.querySelectorAll('.ni').forEach(n=>n.onclick=()=>{cur=+n.dataset.i;render()});
const d=b.querySelector('#ds');if(d)d.onclick=()=>{dark();render()};
const s=b.querySelector('#gs');if(s){const v=Math.round(parseFloat(getComputedStyle(R).getPropertyValue('--g'))*100);s.value=v;b.querySelector('#gv').textContent=v+'%';s.oninput=()=>{setG(s.value);b.querySelector('#gv').textContent=s.value+'%';$('#cg').value=s.value}}}
render()}
</script></body></html>
CHENOS_INDEX_EOF
cat > $C/opt/chenos/launcher.py <<'CHENOS_PY_EOF'
#!/usr/bin/env python3
# ChenOS helper: lets the desktop shell run a few whitelisted commands (localhost only).
import re, subprocess, http.server, urllib.parse as u
ALLOW = {
    "labrador": ["labrador"],
    "files": ["pcmanfm"],
    "terminal": ["x-terminal-emulator"],
    "poweroff": ["sudo", "systemctl", "poweroff"],
    "reboot": ["sudo", "systemctl", "reboot"],
}
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(s):
        p = u.urlparse(s.path); q = u.parse_qs(p.query); cmd = None
        app = q.get("app", [""])[0]; fid = q.get("id", [""])[0]
        if p.path == "/run" and app in ALLOW:
            cmd = ALLOW[app]
        elif p.path == "/install" and re.fullmatch(r"[A-Za-z0-9._-]+", fid):
            cmd = ["flatpak", "install", "--user", "-y", "--noninteractive", "flathub", fid]
        s.send_response(200 if cmd else 404)
        s.send_header("Access-Control-Allow-Origin", "*"); s.end_headers()
        if cmd: subprocess.Popen(cmd)
    def log_message(s, *a): pass
http.server.HTTPServer(("127.0.0.1", 7777), H).serve_forever()
CHENOS_PY_EOF

cat > $C/etc/skel/.xinitrc <<'L'
xset s off -dpms
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo &
python3 /opt/chenos/launcher.py &
openbox &
exec chromium --kiosk --no-first-run --disable-infobars --user-data-dir="$HOME/.chenos" file:///opt/chenos/index.html
L
cat > $C/etc/skel/.profile <<'L'
[ -z "${DISPLAY:-}" ] && [ "$(tty)" = /dev/tty1 ] && exec startx
L

# Labrador: Chromium with its own profile, policy and a red peace icon
cat > $C/usr/local/bin/labrador <<'L'
#!/bin/sh
exec chromium --user-data-dir="$HOME/.labrador" --class=Labrador --no-first-run "$@"
L
chmod +x $C/usr/local/bin/labrador
cat > $C/etc/chromium/policies/managed/labrador.json <<'L'
{"HomepageLocation":"https://www.google.com","ShowHomeButton":true,"BrowserThemeColor":"#ffffff"}
L
cat > $C/usr/share/icons/hicolor/scalable/apps/labrador.svg <<'L'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" rx="23" fill="#fff"/><circle cx="50" cy="50" r="30" fill="none" stroke="#ff3b30" stroke-width="7"/><path d="M50 20v60M50 50L29 71M50 50l21 21" stroke="#ff3b30" stroke-width="7" stroke-linecap="round" fill="none"/></svg>
L
cat > $C/usr/share/applications/labrador.desktop <<'L'
[Desktop Entry]
Type=Application
Name=Labrador
Exec=labrador %U
Icon=labrador
Categories=Network;WebBrowser;
L

cat > config/hooks/live/0100-flathub.hook.chroot <<'L'
#!/bin/sh
flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
L
chmod +x config/hooks/live/0100-flathub.hook.chroot

lb build 2>&1 | tee build.log
mv ./*.iso "/root/glassos-$ARCH.iso"
echo "Done: /root/glassos-$ARCH.iso"

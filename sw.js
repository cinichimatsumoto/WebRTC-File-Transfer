// Direct Drop service worker: lets the page open from the home screen and work from cache when offline.
// The page itself is always fetched fresh when online, so updates appear after a reload.
const C="direct-drop-v1";
const SHELL=["./","index.html","manifest.webmanifest","icon-192.png","icon-512.png","vendor/peerjs.min.js","vendor/qrcode.js"];
self.addEventListener("install",e=>{
  e.waitUntil(caches.open(C).then(c=>Promise.all(SHELL.map(u=>c.add(u).catch(()=>{})))).then(()=>self.skipWaiting()));
});
self.addEventListener("activate",e=>{
  e.waitUntil(caches.keys().then(k=>Promise.all(k.filter(x=>x!==C).map(x=>caches.delete(x)))).then(()=>self.clients.claim()));
});
self.addEventListener("fetch",e=>{
  const r=e.request;
  if(r.method!=="GET"||new URL(r.url).origin!==location.origin)return;
  if(r.mode==="navigate"){
    e.respondWith(fetch(r).then(x=>{const y=x.clone();caches.open(C).then(c=>c.put("index.html",y));return x}).catch(()=>caches.match("index.html")));
    return;
  }
  e.respondWith(caches.match(r).then(h=>h||fetch(r).then(x=>{if(x.ok){const y=x.clone();caches.open(C).then(c=>c.put(r,y))}return x})));
});

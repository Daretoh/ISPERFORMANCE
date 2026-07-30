/* IS Performance OS — Service Worker (PWA) */
var CACHE = 'isp-os-v2';
var SHELL = ['/os/', '/os/index.html', '/os/icon-192.png', '/os/icon-512.png', '/os/maskable-512.png', '/os/apple-touch-icon.png', '/os/manifest.webmanifest'];

self.addEventListener('install', function (e) {
  e.waitUntil(caches.open(CACHE).then(function (c) { return c.addAll(SHELL); }).then(function () { return self.skipWaiting(); }));
});

self.addEventListener('activate', function (e) {
  e.waitUntil(
    caches.keys().then(function (keys) {
      return Promise.all(keys.filter(function (k) { return k !== CACHE; }).map(function (k) { return caches.delete(k); }));
    }).then(function () { return self.clients.claim(); })
  );
});

self.addEventListener('fetch', function (e) {
  var req = e.request;
  if (req.method !== 'GET') return;
  var url = new URL(req.url);
  // No interceptar nada de otro origen (Supabase, CDN de Supabase, etc.): siempre a la red.
  if (url.origin !== location.origin) return;
  // Red primero; si no hay conexión, servir desde cache (o el shell para navegación).
  e.respondWith(
    fetch(req).then(function (res) {
      var copy = res.clone();
      caches.open(CACHE).then(function (c) { c.put(req, copy); });
      return res;
    }).catch(function () {
      return caches.match(req).then(function (r) { return r || caches.match('/os/index.html'); });
    })
  );
});

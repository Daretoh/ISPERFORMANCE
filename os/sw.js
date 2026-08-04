/* IS Performance OS — Service Worker (PWA) */
var CACHE = 'isp-os-v3';

// Notificaciones push (para cuando la app esté cerrada) + al hacer clic, abrir la app
self.addEventListener('push', function (e) {
  var d = {}; try { d = e.data.json(); } catch (err) { d = { title: 'IS Performance OS', body: (e.data ? e.data.text() : '') }; }
  e.waitUntil(self.registration.showNotification(d.title || 'IS Performance OS', {
    body: d.body || '', icon: '/os/icon-192.png', badge: '/os/icon-192.png', data: (d.url || '/os/')
  }));
});
self.addEventListener('notificationclick', function (e) {
  e.notification.close();
  e.waitUntil(clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function (list) {
    for (var i = 0; i < list.length; i++) { if (list[i].url.indexOf('/os/') >= 0 && 'focus' in list[i]) return list[i].focus(); }
    if (clients.openWindow) return clients.openWindow('/os/');
  }));
});
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

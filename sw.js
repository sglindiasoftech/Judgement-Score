// Judgement Scorer service worker
// Bump CACHE_VERSION on every deploy that changes any cached file.
var CACHE_VERSION = 'judgement-v5';
var FILES_TO_CACHE = [
  './',
  './index.html',
  './app.js',
  './manifest.json',
  './icon-192.png',
  './icon-512.png'
];

self.addEventListener('install', function (event) {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_VERSION).then(function (cache) {
      return cache.addAll(FILES_TO_CACHE);
    })
  );
});

self.addEventListener('activate', function (event) {
  event.waitUntil(
    caches.keys().then(function (keys) {
      return Promise.all(
        keys.map(function (key) {
          if (key !== CACHE_VERSION) {
            return caches.delete(key);
          }
        })
      );
    }).then(function () {
      return self.clients.claim();
    })
  );
});

// Cache-first strategy so the app works fully offline.
// Falls back to network, and updates the cache in the background when online.
self.addEventListener('fetch', function (event) {
  if (event.request.method !== 'GET') { return; }

  event.respondWith(
    caches.match(event.request).then(function (cachedResponse) {
      var networkFetch = fetch(event.request).then(function (networkResponse) {
        if (networkResponse && networkResponse.status === 200) {
          var responseClone = networkResponse.clone();
          caches.open(CACHE_VERSION).then(function (cache) {
            cache.put(event.request, responseClone);
          });
        }
        return networkResponse;
      }).catch(function () {
        return cachedResponse;
      });

      return cachedResponse || networkFetch;
    })
  );
});

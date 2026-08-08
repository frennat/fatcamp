/* Fatcamp service worker.
   The app is one HTML file plus a handful of icons, so the whole thing is
   precached on install. After that it runs with no network at all — which is
   the point, because the gym is in a basement.

   Bump CACHE when you change index.html, or installed copies keep the old one. */
const CACHE = "fatcamp-15c96fb144";
const SHELL = [
  "./",
  "./index.html",
  "./manifest.json",
  "./icons/icon-192.png",
  "./icons/icon-512.png",
  "./icons/icon-180.png",
  "./icons/maskable-512.png"
];

self.addEventListener("install", e => {
  e.waitUntil(
    caches.open(CACHE)
      .then(c => c.addAll(SHELL))
      .then(() => self.skipWaiting())
      .catch(() => self.skipWaiting())   /* a missing optional file must not block install */
  );
});

self.addEventListener("activate", e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", e => {
  const req = e.request;
  if(req.method !== "GET") return;
  const url = new URL(req.url);
  if(url.origin !== self.location.origin) return;

  /* Navigations: serve the cached shell immediately, refresh it in the
     background. You always get an app, even with no signal. */
  if(req.mode === "navigate"){
    e.respondWith(
      caches.match("./index.html").then(hit => {
        const net = fetch(req).then(res => {
          if(res && res.ok) caches.open(CACHE).then(c => c.put("./index.html", res.clone()));
          return res;
        }).catch(() => hit);
        return hit || net;
      })
    );
    return;
  }

  e.respondWith(
    caches.match(req).then(hit => hit || fetch(req).then(res => {
      if(res && res.ok && res.type === "basic"){
        const copy = res.clone();
        caches.open(CACHE).then(c => c.put(req, copy));
      }
      return res;
    }).catch(() => hit))
  );
});

self.addEventListener("message", e => {
  if(e.data === "skipWaiting") self.skipWaiting();
});

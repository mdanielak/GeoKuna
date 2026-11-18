'use strict';

const CACHE_NAME = 'geokuna-pwa-v1';
const APP_SHELL_URLS = [
  './',
  'index.html',
  'flutter_bootstrap.js',
  'manifest.json',
  'favicon.png',
  'version.json',
];

const NETWORK_FIRST_PATHS = new Set([
  '/',
  '/index.html',
  '/flutter_bootstrap.js',
  '/version.json',
  '/manifest.json',
]);

function isCorePrecacheUrl(url) {
  if (url.startsWith('assets/assets/maps/')) return false;
  if (url.startsWith('assets/assets/flags/')) return false;
  if (url.startsWith('canvaskit/chromium/')) return false;
  if (url.startsWith('canvaskit/skwasm')) return false;
  return true;
}

async function cacheBatch(cache, urls, concurrency = 6) {
  let index = 0;
  async function worker() {
    while (index < urls.length) {
      const url = urls[index++];
      try {
        const existing = await cache.match(url);
        if (existing) continue;
        const response = await fetch(url, { cache: 'default' });
        if (response && response.ok) {
          await cache.put(url, response);
        }
      } catch (_) {
        // Ignore individual precache failures; runtime cache-first will retry.
      }
    }
  }
  const workers = Array.from({ length: Math.min(concurrency, urls.length) }, worker);
  await Promise.all(workers);
}

self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    (async () => {
      const cache = await caches.open(CACHE_NAME);
      let coreUrls = [...APP_SHELL_URLS];

      try {
        const manifestRes = await fetch('precache_manifest.json', { cache: 'no-store' });
        if (manifestRes.ok) {
          const manifest = await manifestRes.json();
          if (manifest && Array.isArray(manifest.entries)) {
            const manifestUrls = manifest.entries
              .map((entry) => entry.url)
              .filter((url) => typeof url === 'string' && isCorePrecacheUrl(url));
            coreUrls = Array.from(new Set([...coreUrls, ...manifestUrls]));
          }
        }
      } catch (_) {
        // Fallback to app shell URLs if manifest fetch fails.
      }

      await cacheBatch(cache, coreUrls);
    })()
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const keys = await caches.keys();
      await Promise.all(
        keys
          .filter((key) => key !== CACHE_NAME)
          .map((key) => caches.delete(key))
      );

      try {
        const manifestRes = await fetch('precache_manifest.json', { cache: 'no-store' });
        if (manifestRes.ok) {
          const manifest = await manifestRes.json();
          if (manifest && Array.isArray(manifest.entries)) {
            const validUrls = new Set(
              manifest.entries.map((entry) => new URL(entry.url, self.registration.scope).href)
            );
            for (const shellUrl of APP_SHELL_URLS) {
              validUrls.add(new URL(shellUrl, self.registration.scope).href);
            }
            const cache = await caches.open(CACHE_NAME);
            const cachedRequests = await cache.keys();
            await Promise.all(
              cachedRequests
                .filter((req) => !validUrls.has(req.url))
                .map((req) => cache.delete(req))
            );
          }
        }
      } catch (_) {
        // Keep existing cache intact when offline.
      }

      await self.clients.claim();
    })()
  );
});

async function networkFirst(request, fallbackUrl = null) {
  const cache = await caches.open(CACHE_NAME);
  try {
    const response = await fetch(request, { cache: 'no-cache' });
    if (response && response.ok) {
      cache.put(request, response.clone()).catch(() => {});
    }
    return response;
  } catch (_) {
    const cached = await cache.match(request);
    if (cached) return cached;
    if (fallbackUrl) {
      const fallback = await cache.match(fallbackUrl);
      if (fallback) return fallback;
    }
    throw _;
  }
}

async function cacheFirst(request) {
  const cache = await caches.open(CACHE_NAME);
  const cached = await cache.match(request);
  if (cached) return cached;

  const response = await fetch(request);
  if (response && response.ok) {
    cache.put(request, response.clone()).catch(() => {});
  }
  return response;
}

self.addEventListener('fetch', (event) => {
  const { request } = event;
  if (request.method !== 'GET') return;

  const requestUrl = new URL(request.url);
  if (requestUrl.origin !== self.location.origin) return;

  const scopePath = new URL(self.registration.scope).pathname;
  const relativePath = requestUrl.pathname.startsWith(scopePath)
    ? '/' + requestUrl.pathname.slice(scopePath.length)
    : requestUrl.pathname;

  if (relativePath === '/precache_manifest.json' || relativePath === '/sw.js') {
    return;
  }

  if (request.mode === 'navigate') {
    event.respondWith(networkFirst(request, 'index.html'));
    return;
  }

  if (NETWORK_FIRST_PATHS.has(relativePath)) {
    event.respondWith(networkFirst(request));
    return;
  }

  event.respondWith(cacheFirst(request));
});

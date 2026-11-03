/**
 * Offline Service Worker – Mancs Mentőakció (4. fázis).
 *
 * Előre gyorsítótárazza (precache) a teljes alkalmazás-héjat (HTML, CSS,
 * összes ES modul, ikon, manifest), így az első betöltés után internetkapcsolat
 * nélkül (repülőgépes módban is) 100%-ban működik iPaden.
 */
const CACHE_NAME = 'mancs-mentoakcio-cache-v2';

const APP_SHELL = [
  './',
  './index.html',
  './manifest.webmanifest',
  './styles/main.css',
  './assets/icons/icon.svg',
  './dist/bundle.js',
  './src/main.js',
  './src/core/scope.js',
  './src/core/input.js',
  './src/core/stage.js',
  './src/core/stateMachine.js',
  './src/audio/engine.js',
  './src/audio/sfx.js',
  './src/audio/speech.js',
  './src/data/gameData.js',
  './src/data/audioManifest.js',
  './src/art/symbols.js',
  './src/art/pupSvg.js',
  './src/art/scenes.js',
  './src/art/hubArt.js',
  './src/state/progressStore.js',
  './src/state/localStorageAdapter.js',
  './src/state/missionDeck.js',
  './src/screens/splash.js',
  './src/screens/hub.js',
  './src/screens/selection.js',
  './src/screens/action.js',
  './src/screens/reward.js',
  './src/screens/care.js',
  './src/screens/sorter.js',
  './src/minigames/index.js',
  './src/minigames/common.js',
  './src/minigames/placeholder.js',
  './src/minigames/scrub.js',
  './src/minigames/multitap.js',
  './src/minigames/drag.js',
  './src/minigames/shapes.js',
  './src/minigames/peekaboo.js',
  './src/minigames/lasso.js',
  './src/ui/hud.js',
  './src/ui/modal.js',
  './src/ui/confetti.js',
  './src/ui/particles.js',
  './src/ui/guideHand.js',
  './src/ui/scaffolding.js',
  './src/pwa/registerSw.js',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches
      .open(CACHE_NAME)
      .then((cache) => cache.addAll(APP_SHELL))
      .then(() => self.skipWaiting()),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) =>
        Promise.all(
          keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)),
        ),
      )
      .then(() => self.clients.claim()),
  );
});

self.addEventListener('fetch', (event) => {
  const { request } = event;
  if (request.method !== 'GET') return;

  event.respondWith(
    caches.match(request).then((cached) => {
      if (cached) return cached;
      return fetch(request)
        .then((response) => {
          if (
            response &&
            response.status === 200 &&
            response.type === 'basic'
          ) {
            const copy = response.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(request, copy));
          }
          return response;
        })
        .catch(() => caches.match('./index.html'));
    }),
  );
});

import { precacheAndRoute, cleanupOutdatedCaches } from 'workbox-precaching'
import { registerRoute } from 'workbox-routing'
import { StaleWhileRevalidate } from 'workbox-strategies'
import { clientsClaim } from 'workbox-core'

self.skipWaiting()
clientsClaim()
cleanupOutdatedCaches()

// Injected at build time by vite-plugin-pwa (injectManifest strategy)
precacheAndRoute(self.__WB_MANIFEST)

registerRoute(
  ({ url }) => url.origin.includes('supabase.co'),
  new StaleWhileRevalidate({ cacheName: 'supabase-api-cache' }),
)

self.addEventListener('push', (event) => {
  let payload = { title: 'FORGE', body: 'Reminder' }
  try {
    if (event.data) payload = { ...payload, ...event.data.json() }
  } catch {
    payload.body = event.data?.text() ?? payload.body
  }

  event.waitUntil(
    self.registration.showNotification(payload.title, {
      body: payload.body,
      icon: '/icons/192.png',
      badge: '/icons/192.png',
      data: { url: payload.url || '/' },
    }),
  )
})

self.addEventListener('notificationclick', (event) => {
  event.notification.close()
  const targetUrl = event.notification.data?.url || '/'

  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clients) => {
      for (const client of clients) {
        if (client.url.includes(self.location.origin) && 'focus' in client) {
          client.navigate(targetUrl)
          return client.focus()
        }
      }
      return self.clients.openWindow(targetUrl)
    }),
  )
})

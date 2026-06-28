import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// Backend (.NET API + SignalR) ve Ollama yerel adresleri.
const API_TARGET = process.env.VITE_API_PROXY_TARGET || 'http://localhost:5021';
const OLLAMA_TARGET = process.env.VITE_OLLAMA_PROXY_TARGET || 'http://localhost:11434';

export default defineConfig({
  plugins: [react()],
  server: {
    // ngrok/uzak erişim için tüm arayüzlerde dinle.
    host: true,
    // Vite 6+ bilinmeyen Host başlığı gelen istekleri 403 ile engeller.
    // ngrok tüneli üzerinden panele girince yaşanan "Blocked request / 403"
    // hatasının kaynağı budur; tünel alan adlarına izin veriyoruz.
    allowedHosts: [
      'localhost',
      '.ngrok-free.dev',
      '.ngrok-free.app',
      '.ngrok.io',
      'starr-haustorial-robin.ngrok-free.dev',
    ],
    proxy: {
      // Tünel üzerinden HTTPS sayfa, yerel HTTP backend'i çağırınca mixed-content
      // engeline takılmasın diye API ve SignalR aynı origin'den proxy'lenir.
      '/api': { target: API_TARGET, changeOrigin: true },
      '/hubs': { target: API_TARGET, changeOrigin: true, ws: true },
      // Sohbet baloncuğu Ollama'ya buradan ulaşır (/ollama -> :11434).
      '/ollama': {
        target: OLLAMA_TARGET,
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/ollama/, ''),
        configure: (proxy) => {
          // Ollama dış origin'leri (ör. ngrok alan adı) CORS gereği 403 ile
          // reddeder. İstek yerelden geçtiği için Origin/Referer'ı localhost'a
          // çevirip Ollama'yı nasıl başlattığından bağımsız 403'ü önlüyoruz.
          proxy.on('proxyReq', (proxyReq) => {
            proxyReq.setHeader('Origin', OLLAMA_TARGET);
            proxyReq.removeHeader('Referer');
          });
        },
      },
    },
  },
});

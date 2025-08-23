import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    host: true,
    proxy: {
      // Proxy API calls to the backend Express server
      '/api': {
        target: 'http://localhost:3001', // Backend server (server.js)
        changeOrigin: true,
        secure: false,
        // Avoid Vite rewriting or serving index.html for API routes
        configure: (proxy) => {
          proxy.on('proxyReq', (proxyReq) => {
            // Ensure we always pass JSON accept header
            proxyReq.setHeader('Accept', 'application/json');
          });
        },
      },
    },
  },
})

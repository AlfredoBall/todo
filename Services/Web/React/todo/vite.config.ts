import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// Aspire injects services__API__HTTPS__0 with the actual API endpoint
// Fallback to standalone API port if running outside Aspire
const target = process.env.services__API__HTTPS__0 || "https://localhost:7258";

console.log('Vite dev server proxy target for /api:', target);

export default defineConfig({
  base: '/todo/react/',
  plugins: [react()],
  server: {
    port: 5173,
    open: true, // Automatically opens the browser
    proxy: {
      // Proxy requests starting with '/api'
      '/api': {
        target,
        changeOrigin: true,
        secure: false,
        // optional: rewrite the path if needed (e.g., remove /api from the backend request)
        // rewrite: (path) => path.replace(/^\/api/, ''), 
      },
    },
      fs: {
        allow: [
          '.', // search in the current directory
          '../../shared/policies' // allow serving files from the shared folder
        ]
      }
  }
})

import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import fs from 'fs'
import path from 'path'

// const _env = (import.meta && (import.meta as any).env) || {};

const target = process.env.services__API__HTTPS__0 || "https://localhost:5173/api"//_env['VITE_API_BASE_URL'];

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    https: process.env.NODE_ENV === 'development' ? {
      key: fs.readFileSync(path.resolve(__dirname, '../../ssl/localhost.key')),
      cert: fs.readFileSync(path.resolve(__dirname, '../../ssl/localhost.crt')),
    } : undefined,
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
    }
  }
})

import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  build: { outDir: 'dist' },
  server: {
    port: 5173,
    proxy: {
      // hit your local API without CORS headaches
      '/api': 'http://localhost:5000'
    }
  }
})

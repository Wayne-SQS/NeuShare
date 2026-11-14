import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import path from 'path'

export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'src')
    }
  },
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, '/api')
      },
      // 上传目录静态映射 /files/**，开发环境需代理到后端，否则 Vite 会回退到 index.html（SPA）
      '/files': {
        target: 'http://localhost:8080',
        changeOrigin: true
      },
      // AI 智能体服务（Python FastAPI :8000），后端路由本身就是 /ai/*，无需 rewrite
      '/ai': {
        target: 'http://localhost:8000',
        changeOrigin: true
      }
    }
  }
})

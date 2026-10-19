import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  build: {
    outDir: '../assets/invoice_engine_dist',
    emptyOutDir: true,
    rollupOptions: {
      output: {
        entryFileNames: 'invoice-engine.js',
        chunkFileNames: '[name].js',
        assetFileNames: '[name].[ext]',
      },
    },
  },
});

import { resolve } from 'path';
import { defineConfig, externalizeDepsPlugin } from 'electron-vite';
import vue from '@vitejs/plugin-vue';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  main: {
    plugins: [externalizeDepsPlugin()],
    resolve: {
      alias: {
        '@': resolve('src'),
        '@types': resolve('src/types'),
      },
    },
  },
  preload: {
    plugins: [externalizeDepsPlugin()],
    resolve: {
      alias: {
        '@': resolve('src'),
        '@types': resolve('src/types'),
      },
    },
    build: {
      rollupOptions: {
        input: {
          'app-preload': resolve(__dirname, 'src/preload/app-preload.ts'),
          'plugin-preload': resolve(__dirname, 'src/preload/plugin-preload.ts'),
        },
      },
    },
  },
  renderer: {
    resolve: {
      alias: {
        '@': resolve('src'),
        '@renderer': resolve('src/renderer/src'),
        '@types': resolve('src/types'),
      },
    },
    plugins: [vue(), tailwindcss()],
  },
});

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
    build: {
      sourcemap: true,
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
      sourcemap: true,
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
        '@modules': resolve('src/renderer/src/modules'),
        '@components': resolve('src/renderer/src/components'),
        '@stores': resolve('src/renderer/src/stores'),
        '@utils': resolve('src/renderer/src/utils'),
        '@views': resolve('src/renderer/src/views'),
        '@plugins': resolve('src/renderer/src/plugins'),
      },
    },
    plugins: [vue(), tailwindcss()],
    build: {
      sourcemap: true,
    },
  },
});

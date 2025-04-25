// @ts-ignore
import { defineConfig } from 'vite';
import { resolve } from 'path';
import { builtinModules } from 'module';

export default defineConfig({
    build: {
        lib: {
            entry: resolve(__dirname, 'src/extension.ts'),
            formats: ['cjs'],
            fileName: 'extension',
        },
        rollupOptions: {
            external: [
                'vscode',
                ...builtinModules,
                ...builtinModules.map(m => `node:${m}`),
            ],
            output: {
                globals: {
                    vscode: 'vscode',
                },
            },
        },
        sourcemap: true,
        outDir: 'dist',
    },
    resolve: {
        alias: {
            '@': resolve(__dirname, 'src'),
        },
    },
}); 
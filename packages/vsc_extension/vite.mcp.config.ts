// @ts-ignore
import { defineConfig } from 'vite';
import { builtinModules } from 'module';

export default defineConfig({
    build: {
        lib: {
            entry: './src/mcp.ts',
            formats: ['cjs'],
            fileName: () => 'mcp.js'
        },
        outDir: 'dist/mcp',
        rollupOptions: {
            external: [
                '@anthropic-ai/sdk',
                '@modelcontextprotocol/sdk',
                'dotenv',
                'readline/promises',
                'chalk',
                'path',
                'fs',
                'os',
                ...builtinModules,
                ...builtinModules.map(m => `node:${m}`)
            ]
        },
        target: 'node18',
        sourcemap: true
    }
}); 
/**
* 插件商店组件
*/
<script setup lang="ts">
import { ref, onMounted } from 'vue';
import type { PluginStorePlugin } from '@/types';

const plugins = ref<PluginStorePlugin[]>([]);
const loading = ref(false);
const error = ref<string | null>(null);

/**
 * 加载插件列表
 */
const loadPlugins = async () => {
    loading.value = true;
    error.value = null;
    try {
        const result = await window.electron.ipcRenderer.invoke('plugin:getStorePlugins');
        plugins.value = result;
    } catch (e) {
        error.value = e instanceof Error ? e.message : '加载插件列表失败';
    } finally {
        loading.value = false;
    }
};

/**
 * 安装插件
 */
const installPlugin = async (plugin: PluginStorePlugin) => {
    try {
        await window.electron.ipcRenderer.invoke('plugin:install', plugin.id);
        await loadPlugins(); // 重新加载列表以更新状态
    } catch (e) {
        error.value = e instanceof Error ? e.message : '安装插件失败';
    }
};

/**
 * 卸载插件
 */
const uninstallPlugin = async (plugin: PluginStorePlugin) => {
    try {
        await window.electron.ipcRenderer.invoke('plugin:uninstall', plugin.id);
        await loadPlugins(); // 重新加载列表以更新状态
    } catch (e) {
        error.value = e instanceof Error ? e.message : '卸载插件失败';
    }
};

// 组件加载时获取插件列表
onMounted(() => {
    loadPlugins();
});
</script>

<template>
    <div class="plugin-store">
        <div class="header">
            <h2 class="text-xl font-bold">插件商店</h2>
            <button class="btn btn-sm btn-outline" @click="loadPlugins" :disabled="loading">
                刷新
            </button>
        </div>

        <div v-if="loading" class="loading">
            加载中...
        </div>

        <div v-else-if="error" class="error">
            {{ error }}
        </div>

        <div v-else class="plugin-list">
            <div v-for="plugin in plugins" :key="plugin.id" class="plugin-card">
                <div class="plugin-info">
                    <h3 class="plugin-name">{{ plugin.name }}</h3>
                    <p class="plugin-description">{{ plugin.description }}</p>
                    <div class="plugin-meta">
                        <span>作者: {{ plugin.author }}</span>
                        <span>版本: {{ plugin.version }}</span>
                        <span>下载: {{ plugin.downloads }}</span>
                        <span>评分: {{ plugin.rating }}</span>
                    </div>
                </div>
                <div class="plugin-actions">
                    <button v-if="plugin.isInstalled" class="btn btn-sm btn-error" @click="uninstallPlugin(plugin)">
                        卸载
                    </button>
                    <button v-else class="btn btn-sm btn-primary" @click="installPlugin(plugin)">
                        安装
                    </button>
                </div>
            </div>
        </div>
    </div>
</template>

<style scoped>
@reference "../app.css"

.plugin-store {
    @apply p-4;
}

.header {
    @apply flex justify-between items-center mb-4;
}

.plugin-list {
    @apply space-y-4;
}

.plugin-card {
    @apply flex justify-between items-start p-4 bg-base-200 rounded-lg;
}

.plugin-info {
    @apply flex-1;
}

.plugin-name {
    @apply text-lg font-semibold mb-2;
}

.plugin-description {
    @apply text-sm text-base-content/80 mb-2;
}

.plugin-meta {
    @apply text-xs space-x-4 text-base-content/60;
}

.plugin-actions {
    @apply ml-4;
}

.loading {
    @apply text-center py-8 text-base-content/60;
}

.error {
    @apply text-center py-8 text-error;
}
</style>
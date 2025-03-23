/**
* 插件商店组件
* 展示可用的插件列表，并支持按目录分类查看
*/
<script setup lang="ts">
import { ref, computed } from 'vue';
import type { StorePlugin, PluginLocation } from '../../../types/plugin';

// 标签页选项
const tabs: { id: PluginLocation; label: string; directory: string }[] = [
    { id: 'user', label: '用户插件', directory: '' },
    { id: 'builtin', label: '内置插件', directory: '' },
    { id: 'dev', label: '开发插件', directory: '' }
];

// 当前选中的标签页
const activeTab = ref<PluginLocation>('user');

// 插件列表
const plugins = ref<StorePlugin[]>([]);

// 错误信息
const errorMessage = ref<string | null>(null);
// 是否显示错误提示
const showError = ref(false);

// 获取当前标签页的目录信息
const currentDirectory = computed(() => {
    if (plugins.value.length === 0) return '';
    const plugin = plugins.value.find(p =>
        p.directories && (p.currentLocation === activeTab.value || p.recommendedLocation === activeTab.value)
    );
    return plugin?.directories[activeTab.value] || '';
});

// 打开目录
const openDirectory = async () => {
    try {
        const response = await window.electron.ipcRenderer.invoke('plugin:openDirectory', currentDirectory.value);
        if (!response.success) {
            showErrorMessage(response.error || '打开目录失败');
        }
    } catch (error) {
        console.error('Failed to open directory:', error);
        showErrorMessage('打开目录失败');
    }
};

// 显示错误提示
const showErrorMessage = (message: string) => {
    errorMessage.value = message;
    showError.value = true;
    // 3秒后自动隐藏
    setTimeout(() => {
        showError.value = false;
        errorMessage.value = null;
    }, 3000);
};

// 根据当前标签页过滤插件
const filteredPlugins = computed(() => {
    return plugins.value.filter(plugin => {
        // 如果插件已安装，根据其当前位置过滤
        if (plugin.currentLocation) {
            return plugin.currentLocation === activeTab.value;
        }
        // 如果插件未安装，根据其推荐位置过滤
        return plugin.recommendedLocation === activeTab.value;
    });
});

// 从主进程获取插件列表
const loadPlugins = async () => {
    try {
        const response = await window.electron.ipcRenderer.invoke('plugin:getStorePlugins');
        if (response.success) {
            plugins.value = response.plugins;
        } else {
            console.error('Failed to load plugins:', response.error);
            showErrorMessage(response.error || '加载插件列表失败');
            plugins.value = [];
        }
    } catch (error) {
        console.error('Failed to load plugins:', error);
        showErrorMessage('加载插件列表失败');
        plugins.value = [];
    }
};

// 安装插件
const installPlugin = async (pluginId: string) => {
    try {
        const response = await window.electron.ipcRenderer.invoke('plugin:install', pluginId);
        if (response.success) {
            await loadPlugins(); // 重新加载插件列表
        } else {
            console.error('Failed to install plugin:', response.error);
            showErrorMessage(response.error || '安装插件失败');
        }
    } catch (error) {
        console.error('Failed to install plugin:', error);
        showErrorMessage('安装插件失败');
    }
};

// 卸载插件
const uninstallPlugin = async (pluginId: string) => {
    try {
        const response = await window.electron.ipcRenderer.invoke('plugin:uninstall', pluginId);
        if (response.success) {
            await loadPlugins(); // 重新加载插件列表
        } else {
            console.error('Failed to uninstall plugin:', response.error);
            showErrorMessage(response.error || '卸载插件失败');
        }
    } catch (error) {
        console.error('Failed to uninstall plugin:', error);
        showErrorMessage('卸载插件失败');
    }
};

// 组件挂载时加载插件列表
loadPlugins();
</script>

<template>
    <div class="container mx-auto p-4">
        <!-- 错误提示 -->
        <div v-if="showError" class="alert alert-error mb-4">
            <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none"
                viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                    d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <span>{{ errorMessage }}</span>
        </div>

        <!-- 标签页 -->
        <div class="tabs tabs-boxed mb-4">
            <a v-for="tab in tabs" :key="tab.id" :class="['tab', { 'tab-active': activeTab === tab.id }]"
                @click="activeTab = tab.id">
                {{ tab.label }}
            </a>
        </div>

        <!-- 目录信息 -->
        <div v-if="currentDirectory" class="alert alert-info mb-4 flex justify-between items-center">
            <div class="flex items-center">
                <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6 mr-2" fill="none"
                    viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                        d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" />
                </svg>
                <span class="text-sm">{{ currentDirectory }}</span>
            </div>
            <button class="btn btn-sm btn-ghost" @click="openDirectory">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24"
                    stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                        d="M5 19a2 2 0 01-2-2V7a2 2 0 012-2h4l2 2h4a2 2 0 012 2v1M5 19h14a2 2 0 002-2v-5a2 2 0 00-2-2H9a2 2 0 00-2 2v5a2 2 0 01-2 2z" />
                </svg>
                打开目录
            </button>
        </div>

        <!-- 插件列表 -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <div v-for="plugin in filteredPlugins" :key="plugin.id" class="card bg-base-100 shadow-xl">
                <div class="card-body">
                    <h2 class="card-title">
                        {{ plugin.name }}
                        <div class="badge badge-secondary">{{ plugin.version }}</div>
                    </h2>
                    <p>{{ plugin.description }}</p>
                    <div class="flex items-center gap-2 mt-2">
                        <div class="badge badge-outline">{{ plugin.author }}</div>
                        <div class="badge badge-outline">⭐ {{ plugin.rating }}</div>
                        <div class="badge badge-outline">⬇️ {{ plugin.downloads }}</div>
                    </div>
                    <div class="card-actions justify-end mt-4">
                        <!-- 显示插件目录信息 -->
                        <div class="text-sm opacity-70">
                            {{ plugin.currentLocation ? '当前位置' : '推荐位置' }}:
                            {{ plugin.directories[plugin.currentLocation || plugin.recommendedLocation] }}
                        </div>
                        <!-- 安装/卸载按钮 -->
                        <button v-if="!plugin.isInstalled" class="btn btn-primary" @click="installPlugin(plugin.id)">
                            安装
                        </button>
                        <button v-else class="btn btn-error" @click="uninstallPlugin(plugin.id)">
                            卸载
                        </button>
                    </div>
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
/**
* 插件商店组件
* 展示可用的插件列表，并支持按目录分类查看
*/
<script setup lang="ts">
import { ref, computed } from 'vue';
import type { StorePlugin } from '../../../types/plugin';

// 标签页选项
const tabs: { id: 'user' | 'dev'; label: string }[] = [
    { id: 'user', label: '用户插件' },
    { id: 'dev', label: '开发插件' }
];

// 当前选中的标签页
const activeTab = ref<'user' | 'dev'>('user');

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
    setTimeout(() => {
        showError.value = false;
        errorMessage.value = null;
    }, 3000);
};

// 加载插件列表
const loadPlugins = async () => {
    try {
        const response = await window.electron.ipcRenderer.invoke('plugin:getStorePlugins');
        if (response.success) {
            plugins.value = response.plugins;
        } else {
            showErrorMessage(response.error || '加载插件列表失败');
            plugins.value = [];
        }
    } catch (error) {
        console.error('Failed to load plugins:', error);
        showErrorMessage('加载插件列表失败');
        plugins.value = [];
    }
};

// 过滤当前标签页的插件
const filteredPlugins = computed(() => {
    return plugins.value.filter(plugin =>
        plugin.currentLocation === activeTab.value ||
        (!plugin.currentLocation && plugin.recommendedLocation === activeTab.value)
    );
});

// 初始加载
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
                    <h2 class="card-title">{{ plugin.name }}</h2>
                    <p class="text-sm">{{ plugin.description }}</p>
                    <div class="text-sm opacity-70">
                        <p>版本: {{ plugin.version }}</p>
                        <p>作者: {{ plugin.author }}</p>
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
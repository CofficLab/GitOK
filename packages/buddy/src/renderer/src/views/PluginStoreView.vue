/**
* 插件商店视图
*
* 功能：
* 1. 展示插件列表
* 2. 按类型分类显示插件
* 3. 显示插件目录信息
*/
<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import type { StorePlugin } from '@/types/plugin'

// 插件列表
const plugins = ref<StorePlugin[]>([])
const errorMessage = ref('')
const showError = ref(false)

// 当前选中的标签
const activeTab = ref<'builtin' | 'user' | 'dev'>('builtin')

// 加载插件列表
const loadPlugins = async () => {
    try {
        const response = await window.api.plugin.getStorePlugins()
        if (response.success) {
            plugins.value = response.plugins
        } else {
            showErrorMessage('加载插件列表失败')
        }
    } catch (error) {
        showErrorMessage('加载插件列表失败')
    }
}

// 打开目录
const openDirectory = async (directory: string) => {
    try {
        const response = await window.api.plugin.openDirectory(directory)
        if (!response.success) {
            showErrorMessage('无法打开目录')
        }
    } catch (error) {
        showErrorMessage('打开目录失败')
    }
}

// 显示错误信息
const showErrorMessage = (message: string) => {
    errorMessage.value = message
    showError.value = true
    setTimeout(() => {
        showError.value = false
        errorMessage.value = ''
    }, 3000)
}

// 根据标签过滤插件
const filteredPlugins = computed(() => {
    return plugins.value.filter(plugin => {
        if (activeTab.value === 'builtin') return plugin.recommendedLocation === 'builtin'
        if (activeTab.value === 'user') return plugin.recommendedLocation === 'user'
        if (activeTab.value === 'dev') return plugin.recommendedLocation === 'dev'
        return true
    })
})

// 获取当前目录
const currentDirectory = computed(() => {
    const plugin = plugins.value[0]
    if (!plugin?.directories) return ''

    if (activeTab.value === 'builtin') return plugin.directories.builtin
    if (activeTab.value === 'user') return plugin.directories.user
    if (activeTab.value === 'dev') return plugin.directories.dev
    return ''
})

// 标签类型
const tabs = ['builtin', 'user', 'dev'] as const

onMounted(() => {
    loadPlugins()
})
</script>

<template>
    <div class="flex flex-col h-full p-4">
        <!-- 错误提示 -->
        <div v-if="showError" class="mb-4 p-4 bg-red-100 text-red-700 rounded-lg">
            {{ errorMessage }}
        </div>

        <!-- 标签页 -->
        <div class="flex space-x-2 mb-4">
            <button v-for="tab in tabs" :key="tab" @click="activeTab = tab" :class="[
                'px-4 py-2 rounded-lg text-sm font-medium',
                activeTab === tab
                    ? 'bg-blue-500 text-white'
                    : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            ]">
                {{ tab === 'builtin' ? '内置插件' : tab === 'user' ? '用户插件' : '开发插件' }}
            </button>
        </div>

        <!-- 目录信息 -->
        <div v-if="currentDirectory" class="mb-4 p-4 bg-gray-50 rounded-lg flex justify-between items-center">
            <div class="text-sm text-gray-600">
                插件目录：{{ currentDirectory }}
            </div>
            <button @click="openDirectory(currentDirectory)"
                class="px-3 py-1 text-sm bg-blue-500 text-white rounded hover:bg-blue-600">
                打开目录
            </button>
        </div>

        <!-- 插件列表 -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 overflow-y-auto">
            <div v-for="plugin in filteredPlugins" :key="plugin.id"
                class="bg-white p-4 rounded-lg shadow hover:shadow-md transition-shadow">
                <h3 class="text-lg font-semibold mb-2">{{ plugin.name }}</h3>
                <p class="text-gray-600 text-sm mb-4">{{ plugin.description }}</p>
                <div class="flex justify-between items-center text-sm">
                    <span class="text-gray-500">v{{ plugin.version }}</span>
                    <span class="text-gray-500">{{ plugin.author }}</span>
                </div>
            </div>
        </div>
    </div>
</template>
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
import type { SuperPlugin } from '@/types/super_plugin'

const electronApi = window.electron
const pluginApi = electronApi.plugins
const { management } = pluginApi

// 插件列表
const plugins = ref<SuperPlugin[]>([])
const directories = ref<{ user: string; dev: string } | null>(null)
const errorMessage = ref('')
const showError = ref(false)

// 当前选中的标签
const activeTab = ref<'user' | 'dev'>('user')

// 加载插件列表
const loadPlugins = async () => {
    try {
        const response = await management.getStorePlugins()
        if (response.success) {
            plugins.value = response.data || []
        } else {
            showErrorMessage(`加载插件列表失败: ${response.error || '未知错误'}`)
            console.error('加载插件列表失败', response)
        }
    } catch (error) {
        const errorMsg = error instanceof Error ? error.message : String(error)
        showErrorMessage(`加载插件列表失败: ${errorMsg}`)
        console.error('加载插件列表失败', error)
    }
}

// 加载目录信息
const loadDirectories = async () => {
    try {
        const response = await management.getDirectories()
        if (response.success) {
            directories.value = response.directories
        } else {
            showErrorMessage(`加载目录信息失败: ${response.error || '未知错误'}`)
            console.error('加载目录信息失败', response)
        }
    } catch (error) {
        const errorMsg = error instanceof Error ? error.message : String(error)
        showErrorMessage(`加载目录信息失败: ${errorMsg}`)
        console.error('加载目录信息失败', error)
    }
}

// 打开目录
const openDirectory = async (directory: string) => {
    try {
        const response = await management.openDirectory(directory)
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
        if (activeTab.value === 'user') return plugin.type === 'user'
        if (activeTab.value === 'dev') return plugin.type === 'dev'
        return true
    })
})

// 获取当前目录
const currentDirectory = computed(() => {
    if (!directories.value) return null
    if (activeTab.value === 'user') return directories.value.user
    if (activeTab.value === 'dev') return directories.value.dev
    return null
})

// 初始化
onMounted(async () => {
    await loadDirectories()
    await loadPlugins()
})
</script>

<template>
    <div class="p-4 h-full flex flex-col">
        <!-- 错误提示 -->
        <div v-if="showError" class="mb-4 p-4 bg-red-100 text-red-700 rounded">
            {{ errorMessage }}
        </div>

        <!-- 标签栏 -->
        <div class="mb-4 border-b">
            <button @click="activeTab = 'user'"
                :class="['px-4 py-2 -mb-px', activeTab === 'user' ? 'border-b-2 border-blue-500 text-blue-600' : 'text-gray-600']">
                用户插件
            </button>
            <button @click="activeTab = 'dev'"
                :class="['px-4 py-2 -mb-px', activeTab === 'dev' ? 'border-b-2 border-blue-500 text-blue-600' : 'text-gray-600']">
                开发中
            </button>
        </div>

        <!-- 目录信息 -->
        <div v-if="currentDirectory"
            class="mb-4 p-4 bg-gray-50 rounded-lg flex flex-wrap justify-between items-center gap-2">
            <div class="text-sm text-gray-600">
                插件目录：{{ currentDirectory }}
            </div>
            <div class="flex gap-2">
                <button @click="openDirectory(currentDirectory)"
                    class="px-3 py-1 text-sm bg-blue-500 text-white rounded hover:bg-blue-600">
                    打开目录
                </button>
            </div>
        </div>

        <!-- 插件列表 -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 overflow-y-auto">
            <div v-for="plugin in filteredPlugins" :key="plugin.id" :class="['p-4 rounded-lg shadow hover:shadow-md transition-shadow', {
                'bg-white': !plugin.validation,
                'bg-red-50': plugin.validation && !plugin.validation.isValid,
                'bg-green-50': plugin.validation && plugin.validation.isValid
            }]">
                <!-- 验证错误提示 -->
                <div v-if="plugin.validation && !plugin.validation.isValid"
                    class="mb-3 p-2 bg-red-100 text-red-700 text-sm rounded">
                    <div class="font-semibold mb-1">验证失败：</div>
                    <ul class="list-disc list-inside">
                        <li v-for="error in plugin.validation.errors" :key="error">
                            {{ error }}
                        </li>
                    </ul>
                </div>

                <!-- 验证通过提示 -->
                <div v-if="plugin.validation && plugin.validation.isValid"
                    class="mb-3 p-2 bg-green-100 text-green-700 text-sm rounded">
                    <div class="font-semibold">验证通过</div>
                </div>

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
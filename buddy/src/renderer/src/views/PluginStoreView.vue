/**
* 插件商店视图
*
* 功能：
* 1. 展示插件列表
* 2. 按类型分类显示插件
* 3. 显示插件目录信息
* 4. 下载远程仓库插件
*/
<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import type { SuperPlugin } from '@/types/super_plugin'
import PluginCard from '../components/PluginCard.vue'

const electronApi = window.electron
const pluginApi = electronApi.plugins
const { management } = pluginApi

// 插件列表
const plugins = ref<SuperPlugin[]>([])
const remotePlugins = ref<SuperPlugin[]>([])
const directories = ref<{ user: string; dev: string } | null>(null)
const errorMessage = ref('')
const showError = ref(false)

// 下载状态
const downloadingPlugins = ref<Set<string>>(new Set())
const downloadSuccess = ref<Set<string>>(new Set())
const downloadError = ref<Map<string, string>>(new Map())

// 卸载状态
const uninstallingPlugins = ref<Set<string>>(new Set())
const uninstallSuccess = ref<Set<string>>(new Set())
const uninstallError = ref<Map<string, string>>(new Map())

// 当前选中的标签
const activeTab = ref<'user' | 'dev' | 'remote'>('user')

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

// 加载远程插件列表
const loadRemotePlugins = async () => {
    try {
        // 调用主进程方法获取远程插件列表
        const response = await management.getRemotePlugins() as {
            success: boolean;
            data?: SuperPlugin[];
            error?: string;
        };

        if (response.success) {
            remotePlugins.value = response.data || [];
        } else {
            showErrorMessage(`加载远程插件列表失败: ${response.error || '未知错误'}`)
            console.error('加载远程插件列表失败', response)
        }
    } catch (error) {
        const errorMsg = error instanceof Error ? error.message : String(error)
        showErrorMessage(`加载远程插件列表失败: ${errorMsg}`)
        console.error('加载远程插件列表失败', error)
    }
}

// 下载插件
const downloadPlugin = async (plugin: SuperPlugin) => {
    if (downloadingPlugins.value.has(plugin.id)) {
        return // 避免重复下载
    }

    try {
        // 清除之前的下载状态
        downloadSuccess.value.delete(plugin.id)
        downloadError.value.delete(plugin.id)

        // 设置下载中状态
        downloadingPlugins.value.add(plugin.id)

        // 只传递必要的属性，避免克隆问题
        const pluginData = {
            id: plugin.id,
            name: plugin.name,
            version: plugin.version,
            description: plugin.description,
            author: plugin.author,
            type: plugin.type,
            path: plugin.path,
            npmPackage: plugin.npmPackage
        }

        // 调用主进程下载插件
        const response = await management.downloadPlugin(pluginData) as {
            success: boolean;
            data?: boolean;
            error?: string;
        };

        // 更新下载状态
        downloadingPlugins.value.delete(plugin.id)

        if (response.success) {
            downloadSuccess.value.add(plugin.id)
            // 刷新插件列表
            await loadPlugins()

            // 3秒后清除成功状态
            setTimeout(() => {
                downloadSuccess.value.delete(plugin.id)
            }, 3000)
        } else {
            // 设置错误信息，并不再自动清除
            downloadError.value.set(plugin.id, response.error || '下载失败')
            // 同时在全局显示错误信息，方便用户复制
            showErrorMessage(`插件 "${plugin.name}" 下载失败: ${response.error || '未知错误'}`)
        }
    } catch (error) {
        downloadingPlugins.value.delete(plugin.id)
        const errorMsg = error instanceof Error ? error.message : String(error)

        // 设置错误信息，并不再自动清除
        downloadError.value.set(plugin.id, errorMsg)

        // 同时在全局显示错误信息，方便用户复制
        showErrorMessage(`插件 "${plugin.name}" 下载失败: ${errorMsg}`)
    }
}

// 加载目录信息
const loadDirectories = async () => {
    try {
        const response = await management.getDirectories() as {
            success: boolean;
            data?: { user: string; dev: string };
            error?: string
        }

        if (response.success && response.data) {
            directories.value = response.data
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
    // 不再自动隐藏错误信息
}

// 隐藏错误信息
const hideErrorMessage = () => {
    showError.value = false
    errorMessage.value = ''
}

// 复制错误信息到剪贴板
const copyErrorMessage = (message: string) => {
    if (message) {
        navigator.clipboard.writeText(message)
            .then(() => {
                // 可以在这里添加复制成功的提示，但为了简洁，先不添加
                console.log('错误信息已复制到剪贴板')
            })
            .catch(err => {
                console.error('复制错误信息失败:', err)
            })
    }
}

// 根据标签过滤插件
const filteredPlugins = computed(() => {
    if (activeTab.value === 'remote') {
        return remotePlugins.value
    }

    return plugins.value.filter(plugin => {
        if (activeTab.value === 'user') return plugin.type === 'user'
        if (activeTab.value === 'dev') return plugin.type === 'dev'
        return true
    })
})

// 检查插件是否已安装
const isPluginInstalled = computed(() => {
    const installedIds = new Set(plugins.value.map(p => p.id))
    return (id: string) => installedIds.has(id)
})

// 获取当前目录
const currentDirectory = computed(() => {
    if (!directories.value) return null
    if (activeTab.value === 'user') return directories.value.user
    if (activeTab.value === 'dev') return directories.value.dev
    return null
})

// 清除单个插件的错误状态
const clearPluginError = (pluginId: string) => {
    downloadError.value.delete(pluginId)
}

// 卸载插件
const uninstallPlugin = async (plugin: SuperPlugin) => {
    if (uninstallingPlugins.value.has(plugin.id)) {
        return // 避免重复操作
    }

    try {
        // 清除之前的状态
        uninstallSuccess.value.delete(plugin.id)
        uninstallError.value.delete(plugin.id)

        // 设置卸载中状态
        uninstallingPlugins.value.add(plugin.id)

        // 调用主进程卸载插件
        const response = await management.uninstallPlugin(plugin.id) as {
            success: boolean;
            data?: boolean;
            error?: string;
        };

        // 更新卸载状态
        uninstallingPlugins.value.delete(plugin.id)

        if (response.success) {
            uninstallSuccess.value.add(plugin.id)
            // 刷新插件列表
            await loadPlugins()

            // 3秒后清除成功状态
            setTimeout(() => {
                uninstallSuccess.value.delete(plugin.id)
            }, 3000)
        } else {
            // 设置错误信息
            uninstallError.value.set(plugin.id, response.error || '卸载失败')
            // 显示全局错误信息
            showErrorMessage(`插件 "${plugin.name}" 卸载失败: ${response.error || '未知错误'}`)
        }
    } catch (error) {
        uninstallingPlugins.value.delete(plugin.id)
        const errorMsg = error instanceof Error ? error.message : String(error)

        // 设置错误信息
        uninstallError.value.set(plugin.id, errorMsg)

        // 显示全局错误信息
        showErrorMessage(`插件 "${plugin.name}" 卸载失败: ${errorMsg}`)
    }
}

// 清除单个插件的卸载错误状态
const clearUninstallError = (pluginId: string) => {
    uninstallError.value.delete(pluginId)
}

// 初始化
onMounted(async () => {
    await loadDirectories()
    await loadPlugins()
    await loadRemotePlugins()
})
</script>

<template>
    <div class="p-4 h-full flex flex-col">
        <!-- 错误提示 -->
        <div v-if="showError" class="mb-4 p-4 bg-red-100 text-red-700 rounded flex flex-col gap-2">
            <div class="flex justify-between items-start">
                <div class="font-medium">错误信息：</div>
                <button @click="hideErrorMessage" class="text-red-700 hover:text-red-900">
                    <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12">
                        </path>
                    </svg>
                </button>
            </div>
            <div class="whitespace-pre-wrap break-words">{{ errorMessage }}</div>
            <div class="flex justify-end mt-2">
                <button @click="copyErrorMessage(errorMessage)"
                    class="flex items-center px-3 py-1 text-sm bg-red-200 text-red-800 rounded hover:bg-red-300">
                    <svg class="h-4 w-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                            d="M8 5H6a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2v-1M8 5a2 2 0 002 2h2a2 2 0 002-2M8 5a2 2 0 012-2h2a2 2 0 012 2m0 0h2a2 2 0 012 2v3m2 4H10m0 0l3-3m-3 3l3 3">
                        </path>
                    </svg>
                    复制错误信息
                </button>
            </div>
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
            <button @click="activeTab = 'remote'"
                :class="['px-4 py-2 -mb-px', activeTab === 'remote' ? 'border-b-2 border-blue-500 text-blue-600' : 'text-gray-600']">
                远程仓库
            </button>
        </div>

        <!-- 目录信息 -->
        <div v-if="currentDirectory && activeTab !== 'remote'"
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

        <!-- 远程仓库提示 -->
        <div v-if="activeTab === 'remote'" class="mb-4 p-4 bg-blue-50 rounded-lg">
            <div class="text-sm text-blue-600">
                从远程仓库下载插件将会安装到用户插件目录中
            </div>
        </div>

        <!-- 插件列表 -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 overflow-y-auto">
            <!-- 本地插件卡片 -->
            <PluginCard v-if="activeTab !== 'remote'" v-for="plugin in filteredPlugins" :key="plugin.id"
                :plugin="plugin" type="local" :uninstallingPlugins="uninstallingPlugins"
                :uninstallSuccess="uninstallSuccess" :uninstallError="uninstallError" @uninstall="uninstallPlugin"
                @clear-uninstall-error="clearUninstallError" @copy-error="copyErrorMessage" />

            <!-- 远程插件卡片 -->
            <PluginCard v-if="activeTab === 'remote'" v-for="plugin in filteredPlugins" :key="plugin.id"
                :plugin="plugin" type="remote" :downloadingPlugins="downloadingPlugins"
                :downloadSuccess="downloadSuccess" :downloadError="downloadError" :isInstalled="isPluginInstalled"
                @download="downloadPlugin" @clear-download-error="clearPluginError" @copy-error="copyErrorMessage" />

            <!-- 无插件提示 -->
            <div v-if="filteredPlugins.length === 0" class="col-span-full p-8 text-center text-gray-500">
                <p v-if="activeTab === 'remote'">没有可用的远程插件</p>
                <p v-else>没有找到插件</p>
            </div>
        </div>
    </div>
</template>
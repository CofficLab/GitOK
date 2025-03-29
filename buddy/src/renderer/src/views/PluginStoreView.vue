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
import PluginCard from '@renderer/modules/PluginCard.vue'
import { RiRefreshLine, RiFolder2Line } from '@remixicon/vue'
import Alert from '@renderer/components/Alert.vue'  // 导入 Alert 组件
import ToolBar from '@renderer/components/ToolBar.vue'
import ToolBarItem from '@renderer/components/ToolBarItem.vue'
import Empty from '@renderer/components/Empty.vue'

const electronApi = window.electron
const pluginApi = electronApi.plugins
const { management } = pluginApi

const userPlugins = ref<SuperPlugin[]>([])
const remotePlugins = ref<SuperPlugin[]>([])
const directory = ref<string | null>(null)
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

// 加载状态
const loadingPlugins = ref<boolean>(false)
const loadingRemotePlugins = ref<boolean>(false)

// 当前选中的标签
const activeTab = ref<'user' | 'remote'>('user')

// 刷新按钮点击事件
const handleRefresh = async () => {
    if (activeTab.value === 'remote') {
        await loadRemotePlugins(true)
    } else {
        await loadPlugins(true)
    }
}

// 加载插件列表
const loadPlugins = async (forceRefresh = false) => {
    if (loadingPlugins.value && !forceRefresh) return

    loadingPlugins.value = true
    try {
        const response = await management.getStorePlugins()
        if (response.success && response.data) {
            const allPlugins = response.data || []
            userPlugins.value = allPlugins.filter(p => p.type === 'user')
        } else {
            showErrorMessage(`加载插件列表失败: ${response.error || '未知错误'}`)
            console.error('加载插件列表失败', response)
        }
    } catch (err) {
        const errorMsg = err instanceof Error ? err.message : String(err)
        showErrorMessage(`加载插件列表失败: ${errorMsg}`)
        console.error('Failed to load plugins:', err)
    } finally {
        loadingPlugins.value = false
    }
}

// 加载远程插件列表
const loadRemotePlugins = async (forceRefresh = false) => {
    if (loadingRemotePlugins.value && !forceRefresh) return

    loadingRemotePlugins.value = true
    try {
        // 调用主进程方法获取远程插件列表
        const response = await management.getRemotePlugins()

        if (response.success) {
            remotePlugins.value = response.data || []
        } else {
            showErrorMessage(`加载远程插件列表失败: ${response.error || '未知错误'}`)
            console.error('加载远程插件列表失败', response)
        }
    } catch (err) {
        const errorMsg = err instanceof Error ? err.message : String(err)
        showErrorMessage(`加载远程插件列表失败: ${errorMsg}`)
        console.error('Failed to load remote plugins:', err)
    } finally {
        loadingRemotePlugins.value = false
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
            data?: { user: string };
            error?: string
        }

        if (response.success && response.data) {
            directory.value = response.data.user
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
const openDirectory = async (dir: string | null) => {
    if (!dir) return
    try {
        const response = await management.openDirectory(dir)
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
    return userPlugins.value
})

// 检查插件是否已安装
const isPluginInstalled = computed(() => {
    const installedIds = new Set(userPlugins.value.map(p => p.id))
    return (id: string) => installedIds.has(id)
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
        <!-- 标签页 -->
        <div class="mb-4">
            <ToolBar variant="compact" :bordered="false">
                <template #left>
                    <ToolBarItem clickable @click="activeTab = 'user'" :active="activeTab === 'user'">
                        用户插件
                    </ToolBarItem>
                    <ToolBarItem clickable @click="activeTab = 'remote'" :active="activeTab === 'remote'">
                        远程仓库
                    </ToolBarItem>
                </template>
                <template #right>
                    <ToolBarItem clickable @click="() => openDirectory(directory)">
                        <RiFolder2Line class="h-5 w-5" />
                    </ToolBarItem>
                    <ToolBarItem clickable @click="handleRefresh"
                        :disabled="(activeTab === 'remote' && loadingRemotePlugins) || (activeTab !== 'remote' && loadingPlugins)">
                        <RiRefreshLine :class="[
                            'h-5 w-5',
                            (activeTab === 'remote' && loadingRemotePlugins) || (activeTab !== 'remote' && loadingPlugins)
                                ? 'animate-spin text-primary'
                                : ''
                        ]" />
                    </ToolBarItem>
                </template>
            </ToolBar>
        </div>

        <!-- 错误提示 -->
        <Alert v-if="showError" :message="errorMessage" type="error" title="错误信息" closable @close="hideErrorMessage" />

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
            <Empty v-if="filteredPlugins.length === 0" :message="activeTab === 'remote' ? '没有可用的远程插件' : '没有找到插件'" />
        </div>
    </div>
</template>
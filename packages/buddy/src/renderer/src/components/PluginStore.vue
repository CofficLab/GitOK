<script setup lang="ts">
import { ref, onMounted, reactive } from 'vue'

// 插件列表
const localPlugins = ref<PluginInfo[]>([])
const installedPlugins = ref<PluginInfo[]>([])

// 加载状态
const loading = reactive({
    local: false,
    installed: false
})

// 错误状态
const error = reactive({
    local: null as string | null,
    installed: null as string | null
})

// 加载本地插件
const loadLocalPlugins = async () => {
    try {
        loading.local = true
        error.local = null
        localPlugins.value = await window.electron.plugins.getLocalPlugins()
    } catch (err) {
        error.local = err instanceof Error ? err.message : '加载本地插件失败'
        console.error('加载本地插件失败:', err)
    } finally {
        loading.local = false
    }
}

// 加载已安装插件
const loadInstalledPlugins = async () => {
    try {
        loading.installed = true
        error.installed = null
        installedPlugins.value = await window.electron.plugins.getInstalledPlugins()
    } catch (err) {
        error.installed = err instanceof Error ? err.message : '加载已安装插件失败'
        console.error('加载已安装插件失败:', err)
    } finally {
        loading.installed = false
    }
}

// 安装插件
const installPlugin = async (pluginId: string) => {
    try {
        const result = await window.electron.plugins.installPlugin(pluginId)
        if (result.success) {
            // 重新加载插件列表
            await Promise.all([loadLocalPlugins(), loadInstalledPlugins()])
        } else if (result.error) {
            console.error(`安装插件失败: ${result.error}`)
        }
    } catch (err) {
        console.error('安装插件失败:', err)
    }
}

// 卸载插件
const uninstallPlugin = async (pluginId: string) => {
    try {
        const result = await window.electron.plugins.uninstallPlugin(pluginId)
        if (result.success) {
            // 重新加载插件列表
            await Promise.all([loadLocalPlugins(), loadInstalledPlugins()])
        } else if (result.error) {
            console.error(`卸载插件失败: ${result.error}`)
        }
    } catch (err) {
        console.error('卸载插件失败:', err)
    }
}

// 组件挂载时加载插件列表
onMounted(() => {
    Promise.all([loadLocalPlugins(), loadInstalledPlugins()])
})

// 暴露方法给父组件
defineExpose({
    loadLocalPlugins,
    loadInstalledPlugins,
    installPlugin,
    uninstallPlugin
})
</script>

<template>
    <div class="plugin-store h-full p-4 overflow-auto">
        <h2 class="text-xl font-bold mb-4">插件商店</h2>

        <!-- 本地插件 -->
        <div class="mb-8">
            <h3 class="text-lg font-semibold mb-2 flex items-center">
                <span>本地插件</span>
                <button @click="loadLocalPlugins" class="btn btn-xs btn-ghost ml-2">
                    <i class="i-mdi-refresh"></i>
                </button>
            </h3>

            <div v-if="loading.local" class="text-center py-4">
                <span class="loading loading-spinner loading-md"></span>
                <span class="ml-2">加载中...</span>
            </div>

            <div v-else-if="error.local" class="text-center py-4 text-error">
                <div>{{ error.local }}</div>
                <button @click="loadLocalPlugins" class="btn btn-sm btn-outline btn-error mt-2">重试</button>
            </div>

            <div v-else-if="localPlugins.length === 0" class="text-center py-4 text-base-content/50">
                暂无本地插件
            </div>

            <div v-else class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                <div v-for="plugin in localPlugins" :key="plugin.id" class="card bg-base-200 shadow-sm">
                    <div class="card-body p-4">
                        <h3 class="card-title text-base">{{ plugin.name }}</h3>
                        <p class="text-sm">{{ plugin.description }}</p>
                        <div class="text-xs opacity-70 mt-1">
                            <span>版本: {{ plugin.version }}</span>
                            <span class="mx-1">|</span>
                            <span>作者: {{ plugin.author }}</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- 已安装插件 -->
        <div>
            <h3 class="text-lg font-semibold mb-2 flex items-center">
                <span>已安装插件</span>
                <button @click="loadInstalledPlugins" class="btn btn-xs btn-ghost ml-2">
                    <i class="i-mdi-refresh"></i>
                </button>
            </h3>

            <div v-if="loading.installed" class="text-center py-4">
                <span class="loading loading-spinner loading-md"></span>
                <span class="ml-2">加载中...</span>
            </div>

            <div v-else-if="error.installed" class="text-center py-4 text-error">
                <div>{{ error.installed }}</div>
                <button @click="loadInstalledPlugins" class="btn btn-sm btn-outline btn-error mt-2">重试</button>
            </div>

            <div v-else-if="installedPlugins.length === 0" class="text-center py-4 text-base-content/50">
                暂无已安装插件
            </div>

            <div v-else class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                <div v-for="plugin in installedPlugins" :key="plugin.id" class="card bg-base-200 shadow-sm">
                    <div class="card-body p-4">
                        <h3 class="card-title text-base">{{ plugin.name }}</h3>
                        <p class="text-sm">{{ plugin.description }}</p>
                        <div class="text-xs opacity-70 mt-1">
                            <span>版本: {{ plugin.version }}</span>
                            <span class="mx-1">|</span>
                            <span>作者: {{ plugin.author }}</span>
                        </div>
                        <div class="card-actions justify-end mt-2">
                            <button @click="uninstallPlugin(plugin.id)" class="btn btn-xs btn-error">卸载</button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>
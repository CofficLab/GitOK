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
import { computed } from 'vue'
import PluginCard from '@/renderer/src/components/PluginCard.vue'
import ButtonFolder from '@renderer/cosy/ButtonFolder.vue'
import ButtonRefresh from '@renderer/cosy/ButtonRefresh.vue'
import Empty from '@renderer/cosy/Empty.vue'
import ToolBar from '@renderer/cosy/ToolBar.vue'
import { globalToast } from '../composables/useToast'
import { useMarketStore } from '../stores/marketStore'
import { useDirectory } from '../composables/useDirectory'
import { useAlert } from '../composables/useAlert'
import { useAsyncState, useStorage } from '@vueuse/core'

const { openDirectory } = useDirectory()
const { error } = useAlert()

const marketStore = useMarketStore()
const userPlugins = computed(() => marketStore.userPlugins)
const devPlugins = computed(() => marketStore.devPlugins)
const remotePlugins = computed(() => marketStore.remotePlugins)
const directory = computed(() => marketStore.userPluginDirectory)

// 使用localStorage保存最后选择的标签
const activeTab = useStorage<'user' | 'remote' | 'dev'>(
    'market-active-tab',
    'user'
)

// 加载插件状态管理（合并原有的两个加载状态变量）
const { state: isLoading, execute: loadPlugins } = useAsyncState(
    async () => {
        try {
            switch (activeTab.value) {
                case "remote":
                    await marketStore.loadRemotePlugins()
                    break
                case "user":
                    await marketStore.loadUserPlugins()
                    break
                case "dev":
                    await marketStore.loadDevPlugins()
                    break
                default:
                    error('未知标签')
                    return false
            }

            globalToast.success(`刷新成功(${activeTab.value})`, { duration: 2000, position: 'bottom-center' })
            return true
        } catch (err) {
            error('刷新失败' + err)
            return false
        }
    },
    false,
    { immediate: false, resetOnExecute: true }
)

// 简单使用Vue自带的computed
const shouldShowEmpty = computed(() => {
    return (activeTab.value === 'remote' && remotePlugins.value.length === 0) ||
        (activeTab.value === 'user' && userPlugins.value.length === 0) ||
        (activeTab.value === 'dev' && devPlugins.value.length === 0)
})

// 卸载状态 (使用Map合并处理)
const uninstallStates = useStorage('uninstall-states', {
    uninstallingPlugins: new Set<string>(),
    uninstallSuccess: new Set<string>(),
    uninstallError: new Map<string, string>()
})

// 刷新按钮点击事件
const handleRefresh = () => {
    loadPlugins()
}

// 切换标签并加载对应插件
const switchTab = (tab: 'user' | 'remote' | 'dev') => {
    activeTab.value = tab
    loadPlugins()
}

// 清除单个插件的卸载错误状态
const clearUninstallError = (pluginId: string) => {
    uninstallStates.value.uninstallError.delete(pluginId)
}
</script>

<template>
    <div class="p-4 h-full flex flex-col">
        <!-- 操作栏 -->
        <div class="mb-4 sticky top-0">
            <ToolBar variant="compact" :bordered="false">
                <template #left>
                    <div role="tablist" class="tabs tabs-box bg-primary/50 shadow-inner">
                        <a role="tab" class="tab" :class="{ 'tab-active': activeTab === 'user' }"
                            @click="switchTab('user')">
                            用户插件
                        </a>
                        <a role="tab" class="tab" :class="{ 'tab-active': activeTab === 'remote' }"
                            @click="switchTab('remote')">
                            远程仓库
                        </a>
                        <a role="tab" class="tab" :class="{ 'tab-active': activeTab === 'dev' }"
                            @click="switchTab('dev')">
                            开发插件
                        </a>
                    </div>
                </template>

                <template #right>
                    <ButtonFolder @click="() => openDirectory(directory)" shape="circle" size="sm" tooltip="打开插件目录" />
                    <ButtonRefresh @click="handleRefresh" shape="circle" :loading="isLoading" :disabled="isLoading"
                        tooltip="刷新插件列表" size="sm" />
                </template>
            </ToolBar>
        </div>

        <!-- 插件列表 -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <!-- 本地插件卡片 -->
            <PluginCard v-if="activeTab === 'user'" v-for="plugin in userPlugins" :key="plugin.id" :plugin="plugin"
                type="local" :uninstallingPlugins="uninstallStates.uninstallingPlugins"
                :uninstallSuccess="uninstallStates.uninstallSuccess" :uninstallError="uninstallStates.uninstallError"
                @uninstall="marketStore.uninstallPlugin" @clear-uninstall-error="clearUninstallError" />

            <!-- 远程插件卡片 -->
            <PluginCard v-if="activeTab === 'remote'" v-for="plugin in remotePlugins" :key="plugin.id" :plugin="plugin"
                type="remote" />

            <!-- 开发插件卡片 -->
            <PluginCard v-if="activeTab === 'dev'" v-for="plugin in devPlugins" :key="plugin.id" :plugin="plugin"
                type="remote" />

            <!-- 无插件提示 -->
            <Empty v-if="shouldShowEmpty" :message="activeTab === 'remote' ? '没有可用的远程插件' : '没有找到插件'" />
        </div>
    </div>
</template>
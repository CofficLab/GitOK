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
import { ref, computed } from 'vue'
import PluginCard from '@renderer/modules/PluginCard.vue'
import ButtonFolder from '@renderer/cosy/ButtonFolder.vue'
import ButtonRefresh from '@renderer/cosy/ButtonRefresh.vue'
import Alert from '@renderer/cosy/Alert.vue'
import Empty from '@renderer/cosy/Empty.vue'
import ToolBar from '@renderer/cosy/ToolBar.vue'
import { globalToast } from '../composables/useToast'
import { useMarketStore } from '../stores/marketStore'
import { useClipboard } from '../composables/useClipboard'
import { ipcAPI } from '@renderer/api/ipc-api'

const userPlugins = computed(() => marketStore.userPlugins)
const devPlugins = computed(() => marketStore.devPlugins)
const remotePlugins = computed(() => marketStore.remotePlugins)
const errorMessage = ref('')
const showError = ref(false)
const marketStore = useMarketStore()
const directory = computed(() => marketStore.userPluginDirectory)

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
const activeTab = ref<'user' | 'remote' | 'dev'>('user')

// 刷新按钮点击事件
const handleRefresh = async () => {
    console.log('handleRefresh')
    if (activeTab.value === 'remote') {
        console.log('handleRefresh remote')
        await marketStore.loadRemotePlugins()
    } else {
        await marketStore.loadUserPlugins()
    }

    globalToast.success('刷新成功', { duration: 2000, position: 'bottom-center' })
}

// 打开目录
const openDirectory = async (dir: string | null) => {
    if (!dir) return
    try {
        await ipcAPI.openFolder(dir)
            showErrorMessage('已打开目录')
    } catch (error) {
        showErrorMessage('打开目录失败: ' + error)
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

const { copyToClipboard } = useClipboard()

// 复制错误信息到剪贴板
const copyErrorMessage = (message: string) => {
    if (message) {
        copyToClipboard(message)
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


// 清除单个插件的卸载错误状态
const clearUninstallError = (pluginId: string) => {
    uninstallError.value.delete(pluginId)
}
</script>

<template>
    <div class="p-4 h-full flex flex-col">
        <!-- 操作栏 -->
        <div class="mb-4">
            <ToolBar variant="compact" :bordered="false">
                <template #left>
                    <!-- 使用 DaisyUI tabs 组件 -->
                    <div role="tablist" class="tabs tabs-box bg-base-200">
                        <a role="tab" class="tab" :class="{ 'tab-active': activeTab === 'user' }"
                            @click="activeTab = 'user'">
                            用户插件
                        </a>
                        <a role="tab" class="tab" :class="{ 'tab-active': activeTab === 'remote' }"
                            @click="activeTab = 'remote'">
                            远程仓库
                        </a>
                        <a role="tab" class="tab" :class="{ 'tab-active': activeTab ==='dev' }"
                            @click="activeTab ='dev'">
                            开发插件
                        </a>
                    </div>
                </template>

                <template #right>
                    <ButtonFolder @click="() => openDirectory(directory)" shape="circle" size="sm" tooltip="打开插件目录" />
                    <ButtonRefresh @click="handleRefresh" shape="circle"
                        :loading="loadingPlugins || loadingRemotePlugins"
                        :disabled="loadingPlugins || loadingRemotePlugins" tooltip="刷新插件列表" size="sm" />
                </template>
            </ToolBar>
        </div>

        <!-- 错误提示 -->
        <Alert v-if="showError" :message="errorMessage" type="error" title="错误信息" closable @close="hideErrorMessage" />

        <!-- 插件列表 -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 overflow-y-auto">
            <!-- 本地插件卡片 -->
            <PluginCard v-if="activeTab !== 'remote'" v-for="plugin in userPlugins" :key="plugin.id"
                :plugin="plugin" type="local" :uninstallingPlugins="uninstallingPlugins"
                :uninstallSuccess="uninstallSuccess" :uninstallError="uninstallError"
                @uninstall="marketStore.uninstallPlugin" @clear-uninstall-error="clearUninstallError"
                @copy-error="copyErrorMessage" />

            <!-- 远程插件卡片 -->
            <PluginCard v-if="activeTab === 'remote'" v-for="plugin in remotePlugins" :key="plugin.id"
                :plugin="plugin" type="remote" :downloadingPlugins="downloadingPlugins"
                :downloadSuccess="downloadSuccess" :downloadError="downloadError" :isInstalled="isPluginInstalled"
                @download="marketStore.downloadPlugin" @clear-download-error="clearPluginError"
                @copy-error="copyErrorMessage" />

            <!-- 开发插件卡片 -->
            <!-- 远程插件卡片 -->
            <PluginCard v-if="activeTab === 'dev'" v-for="plugin in devPlugins" :key="plugin.id"
                :plugin="plugin" type="remote" :downloadingPlugins="downloadingPlugins"
                :downloadSuccess="downloadSuccess" :downloadError="downloadError" :isInstalled="isPluginInstalled"
                @download="marketStore.downloadPlugin" @clear-download-error="clearPluginError"
                @copy-error="copyErrorMessage" />

            <!-- 无插件提示 -->
            <Empty v-if="filteredPlugins.length === 0" :message="activeTab === 'remote' ? '没有可用的远程插件' : '没有找到插件'" />
        </div>
    </div>
</template>
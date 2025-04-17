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
import PluginCard from '@/renderer/src/components/PluginCard.vue'
import ButtonFolder from '@renderer/cosy/ButtonFolder.vue'
import ButtonRefresh from '@renderer/cosy/ButtonRefresh.vue'
import Empty from '@renderer/cosy/Empty.vue'
import ToolBar from '@renderer/cosy/ToolBar.vue'
import { globalToast } from '../composables/useToast'
import { useMarketStore } from '../stores/marketStore'
import { useDirectory } from '../composables/useDirectory'
import { useAlert } from '../composables/useAlert'

const { openDirectory } = useDirectory()
const { error } = useAlert()

const marketStore = useMarketStore()
const userPlugins = computed(() => marketStore.userPlugins)
const devPlugins = computed(() => marketStore.devPlugins)
const remotePlugins = computed(() => marketStore.remotePlugins)
const directory = computed(() => marketStore.userPluginDirectory)

// 加载状态
const loadingPlugins = ref<boolean>(false)
const loadingRemotePlugins = ref<boolean>(false)

// 卸载状态
const uninstallingPlugins = ref<Set<string>>(new Set())
const uninstallSuccess = ref<Set<string>>(new Set())
const uninstallError = ref<Map<string, string>>(new Map())

// 当前选中的标签
const activeTab = ref<'user' | 'remote' | 'dev'>('user')

const shouldShowEmpty = computed(() => {
    return (activeTab.value === 'remote' && remotePlugins.value.length === 0) ||
        (activeTab.value === 'user' && userPlugins.value.length === 0) ||
        (activeTab.value === 'dev' && devPlugins.value.length === 0)
})

// 刷新按钮点击事件
const handleRefresh = async () => {
    switch (activeTab.value) {
        case "remote":
            await marketStore.loadRemotePlugins()
            break;
        case "user":
            await marketStore.loadUserPlugins()
            break;
        case "dev":
            await marketStore.loadDevPlugins()
            break;

        default:
            error('未知标签')
            return;
    }

    globalToast.success(`刷新成功(${activeTab.value})`, { duration: 2000, position: 'bottom-center' })
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
                    <div role="tablist" class="tabs tabs-box bg-primary/50 shadow-inner">
                        <a role="tab" class="tab" :class="{ 'tab-active': activeTab === 'user' }"
                            @click="activeTab = 'user'">
                            用户插件
                        </a>
                        <a role="tab" class="tab" :class="{ 'tab-active': activeTab === 'remote' }"
                            @click="activeTab = 'remote'">
                            远程仓库
                        </a>
                        <a role="tab" class="tab" :class="{ 'tab-active': activeTab === 'dev' }"
                            @click="activeTab = 'dev'">
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

        <!-- 插件列表 -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <!-- 本地插件卡片 -->
            <PluginCard v-if="activeTab === 'user'" v-for="plugin in userPlugins" :key="plugin.id" :plugin="plugin"
                type="local" :uninstallingPlugins="uninstallingPlugins" :uninstallSuccess="uninstallSuccess"
                :uninstallError="uninstallError" @uninstall="marketStore.uninstallPlugin"
                @clear-uninstall-error="clearUninstallError" />

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
<script setup lang="ts">
import { computed } from 'vue'
import {
    RiCheckLine,
    RiDeleteBinLine
} from '@remixicon/vue'
import Button from '@renderer/cosy/Button.vue'
import { globalConfirm } from '@renderer/composables/useConfirm'
import { useMarketStore } from '@renderer/stores/marketStore'
import { globalToast } from '@renderer/composables/useToast'
import { marketIpc } from '../ipc/market-ipc'
import { SendablePlugin } from '@/types/sendable-plugin'
import { useAsyncState, useTimeoutFn } from '@vueuse/core'

const props = defineProps<{
    plugin: SendablePlugin
    downloadingPlugins?: Set<string>
    downloadSuccess?: Set<string>
    downloadError?: Map<string, string>
    uninstallingPlugins?: Set<string>
    uninstallSuccess?: Set<string>
    uninstallError?: Map<string, string>
}>()

// 状态管理
const marketStore = useMarketStore()

// 检查插件安装状态
const { state: isInstalled } = useAsyncState(
    () => marketIpc.isInstalled(props.plugin.id),
    false,
    { immediate: true }
)

// 下载状态管理
const { state: isDownloading, execute: executeDownload } = useAsyncState(
    async () => {
        await marketStore.downloadPlugin(props.plugin)
        isInstalled.value = true
        showDownloadSuccess()
        return true
    },
    false,
    { immediate: false }
)

// 下载成功状态与超时清除
const { isPending: downloadComplete, start: showDownloadSuccess } = useTimeoutFn(
    () => { },
    3000,
    { immediate: false }
)

// 卸载状态管理
const { state: isUninstalling, execute: executeUninstall } = useAsyncState(
    async () => {
        try {
            await marketStore.uninstallPlugin(props.plugin.id)
            setTimeout(() => {
                globalToast.success('插件已卸载')
            }, 500)
            return true
        } catch (err) {
            globalToast.error('卸载失败' + err)
            return false
        }
    },
    false,
    { immediate: false }
)

// 计算卡片样式
const cardClass = computed(() => {
    if (props.plugin.type === 'remote') return 'bg-primary/10'
    if (props.plugin.type === 'dev') return 'bg-secondary/40'

    return {
        'bg-base-100': props.plugin.status === 'inactive',
        'bg-error bg-opacity-10': props.plugin.status === 'error',
        'bg-success bg-opacity-10': props.plugin.status === 'active'
    }
})

// 判断是否是用户安装的插件（可卸载）
const isUserPlugin = computed(() => props.plugin.type === 'user')

// 下载插件
const handleDownload = () => {
    executeDownload()
}

// 显示卸载确认
const confirmUninstall = async () => {
    const confirmed = await globalConfirm.confirm({
        title: '卸载插件',
        message: '确定要卸载此插件吗？',
        confirmText: '确认卸载'
    })

    if (confirmed) {
        executeUninstall()
    }
}
</script>

<template>
    <transition name="card-fade" appear>
        <div class="p-4 rounded-lg shadow-md hover:shadow-lg transition-all duration-300" :class="cardClass">
            <!-- 插件详细信息 -->
            <div class="flex justify-between items-center text-sm border-b border-secondary/20 mb-2">
                <h3 class="text-lg font-semibold mb-2">{{ plugin.name }}</h3>
                <span class="text-base-content/60">v{{ plugin.version }}</span>
                <span class="text-base-content/60">{{ plugin.author }}</span>
            </div>

            <!-- 插件基本信息 -->
            <p class="text-base-content/70 text-sm mb-4">{{ plugin.description }}</p>

            <!-- 操作区域 -->
            <div class="mt-4 flex flex-wrap gap-2 items-center" v-if="plugin.type != 'dev'">
                <!-- 本地插件操作 -->
                <template v-if="plugin.type === 'user'">
                    <!-- 卸载按钮 (仅用户插件) -->
                    <div v-if="isUserPlugin">
                        <!-- 卸载按钮 -->
                        <Button variant="primary" @click="confirmUninstall"
                            :loading="uninstallingPlugins?.has(plugin.id) || isUninstalling">
                            <RiDeleteBinLine class="mr-1 h-4 w-4" />
                            {{ (uninstallingPlugins?.has(plugin.id) || isUninstalling) ? '卸载中...' : '卸载' }}
                        </Button>
                    </div>
                </template>

                <!-- 远程插件操作 -->
                <template v-if="plugin.type == 'remote'">
                    <Button @click="handleDownload" variant="primary" :loading="isDownloading"
                        :disabled="isDownloading || isInstalled">
                        {{ isInstalled ? '已安装' : (isDownloading ? '下载中...' : '下载') }}
                    </Button>
                    <!-- 下载成功提示 -->
                    <transition name="fade">
                        <span v-if="downloadComplete" class="text-xs text-success flex items-center">
                            <RiCheckLine class="h-3 w-3 mr-1" />
                            下载成功
                        </span>
                    </transition>
                </template>
            </div>
        </div>
    </transition>
</template>

<style scoped>
/* 卡片淡入淡出效果 */
.card-fade-enter-active,
.card-fade-leave-active {
    transition: all 0.3s ease;
}

.card-fade-enter-from,
.card-fade-leave-to {
    opacity: 0;
    transform: translateY(10px);
}

/* 淡入淡出效果 */
.fade-enter-active,
.fade-leave-active {
    transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
    opacity: 0;
}

/* 滑动淡入淡出效果 */
.slide-fade-enter-active {
    transition: all 0.3s ease-out;
}

.slide-fade-leave-active {
    transition: all 0.2s cubic-bezier(1, 0.5, 0.8, 1);
}

.slide-fade-enter-from,
.slide-fade-leave-to {
    transform: translateY(-10px);
    opacity: 0;
}
</style>
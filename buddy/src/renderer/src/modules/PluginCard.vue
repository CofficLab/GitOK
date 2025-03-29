/**
* 插件卡片组件
* 用于展示插件信息，支持卸载和下载操作
*/
<script setup lang="ts">
import { computed, ref } from 'vue'
import type { SuperPlugin } from '@/types/super_plugin'
import {
    RiCheckLine,
    RiCloseLine,
    RiDeleteBinLine
} from '@remixicon/vue'
import Button from '@renderer/cosy/Button.vue'
import { globalConfirm } from '@renderer/composables/useConfirm'

const props = defineProps<{
    plugin: SuperPlugin
    type: 'local' | 'remote'
    // 状态控制
    downloadingPlugins?: Set<string>
    downloadSuccess?: Set<string>
    downloadError?: Map<string, string>
    uninstallingPlugins?: Set<string>
    uninstallSuccess?: Set<string>
    uninstallError?: Map<string, string>
    isInstalled?: (id: string) => boolean
}>()

// 动画控制状态
const isUninstalling = ref(false)
const uninstallComplete = ref(false)

const emit = defineEmits<{
    // 操作事件
    (e: 'download', plugin: SuperPlugin): void
    (e: 'uninstall', plugin: SuperPlugin): void
    (e: 'clear-download-error', pluginId: string): void
    (e: 'clear-uninstall-error', pluginId: string): void
    (e: 'copy-error', message: string): void
}>()

// 计算卡片样式
const cardClass = computed(() => {
    if (props.type === 'remote') return 'bg-base-100'

    return {
        'bg-base-100': !props.plugin.validation,
        'bg-error bg-opacity-10': props.plugin.validation && !props.plugin.validation.isValid,
        'bg-success bg-opacity-10': props.plugin.validation && props.plugin.validation.isValid
    }
})

// 判断是否是用户安装的插件（可卸载）
const isUserPlugin = computed(() => props.plugin.type === 'user')

// 复制错误信息
const copyErrorMessage = (message: string | undefined) => {
    if (message) {
        emit('copy-error', message)
    }
}

// 清除下载错误
const clearDownloadError = (pluginId: string) => {
    emit('clear-download-error', pluginId)
}

// 清除卸载错误
const clearUninstallError = (pluginId: string) => {
    emit('clear-uninstall-error', pluginId)
}

// 下载插件
const handleDownload = () => {
    emit('download', props.plugin)
}

// 显示卸载确认
const confirmUninstall = async () => {
    const confirmed = await globalConfirm.confirm({
        title: '卸载插件',
        message: '确定要卸载此插件吗？',
        confirmText: '确认卸载'
    })
    
    if (confirmed) {
        handleUninstall()
    }
}

// 卸载插件
const handleUninstall = async () => {
    isUninstalling.value = true

    // 发送卸载事件
    emit('uninstall', props.plugin)

    // 卸载完成后触发动画
    setTimeout(() => {
        // 判断是否成功卸载
        if (props.uninstallSuccess?.has(props.plugin.id)) {
            uninstallComplete.value = true
        }
        isUninstalling.value = false
    }, 500)
}
</script>

<template>
    <transition name="card-fade" appear>
        <div class="p-4 rounded-lg shadow-md hover:shadow-lg transition-all duration-300" :class="cardClass">
            <!-- 插件基本信息 -->
            <h3 class="text-lg font-semibold mb-2">{{ plugin.name }}</h3>
            <p class="text-base-content/70 text-sm mb-4">{{ plugin.description }}</p>

            <!-- 插件详细信息 -->
            <div class="flex justify-between items-center text-sm">
                <span class="text-base-content/60">v{{ plugin.version }}</span>
                <span class="text-base-content/60">{{ plugin.author }}</span>
            </div>

            <!-- 操作区域 -->
            <div class="mt-4 flex flex-wrap gap-2 items-center">
                <!-- 本地插件操作 -->
                <template v-if="type === 'local'">
                    <!-- 卸载按钮 (仅用户插件) -->
                    <div v-if="isUserPlugin">
                        <!-- 卸载按钮 -->
                        <Button variant="primary" @click="confirmUninstall"
                            :loading="uninstallingPlugins?.has(plugin.id) || isUninstalling">
                            <RiDeleteBinLine class="mr-1 h-4 w-4" />
                            {{ (uninstallingPlugins?.has(plugin.id) || isUninstalling) ? '卸载中...' : '卸载' }}
                        </Button>
                    </div>

                    <!-- 卸载成功提示 -->
                    <transition name="fade">
                        <span v-if="uninstallSuccess?.has(plugin.id)" class="text-xs text-success flex items-center">
                            <RiCheckLine class="h-3 w-3 mr-1" />
                            卸载成功
                        </span>
                    </transition>

                    <!-- 卸载错误提示 -->
                    <transition name="fade">
                        <div v-if="uninstallError?.has(plugin.id)" class="text-xs text-error flex items-center">
                            <span>卸载失败: {{ uninstallError.get(plugin.id) }}</span>
                            <Button size="sm" variant="ghost" @click="clearUninstallError(plugin.id)">
                                <RiCloseLine class="h-3 w-3" />
                            </Button>
                        </div>
                    </transition>
                </template>

                <!-- 远程插件操作 -->
                <template v-else>
                    <Button @click="handleDownload" variant="primary"
                        :loading="downloadingPlugins?.has(plugin.id)"
                        :disabled="downloadingPlugins?.has(plugin.id) || isInstalled?.(plugin.id)">
                        {{ isInstalled?.(plugin.id) ? '已安装' : '下载' }}
                    </Button>
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
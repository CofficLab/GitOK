/**
* 插件卡片组件
* 用于展示插件信息，支持卸载和下载操作
*/
<script setup lang="ts">
import { computed, ref } from 'vue'
import type { SuperPlugin } from '@/types/super_plugin'

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
const showUninstallConfirm = ref(false)
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
    if (props.type === 'remote') return 'bg-white'

    return {
        'bg-white': !props.plugin.validation,
        'bg-red-50': props.plugin.validation && !props.plugin.validation.isValid,
        'bg-green-50': props.plugin.validation && props.plugin.validation.isValid
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
const confirmUninstall = () => {
    showUninstallConfirm.value = true
}

// 取消卸载
const cancelUninstall = () => {
    showUninstallConfirm.value = false
}

// 卸载插件
const handleUninstall = async () => {
    isUninstalling.value = true
    showUninstallConfirm.value = false

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
        <div class="p-4 rounded-lg shadow hover:shadow-md transition-all duration-300" :class="cardClass">
            <!-- 本地插件验证状态 -->
            <template v-if="type === 'local'">
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
            </template>

            <!-- 下载状态 (仅远程插件) -->
            <template v-if="type === 'remote'">
                <transition name="fade" mode="out-in">
                    <div v-if="downloadingPlugins?.has(plugin.id)" key="downloading"
                        class="mb-3 p-2 bg-blue-100 text-blue-700 text-sm rounded flex items-center">
                        <svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-blue-700" xmlns="http://www.w3.org/2000/svg"
                            fill="none" viewBox="0 0 24 24">
                            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4">
                            </circle>
                            <path class="opacity-75" fill="currentColor"
                                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z">
                            </path>
                        </svg>
                        <span>下载中...</span>
                    </div>

                    <div v-else-if="downloadSuccess?.has(plugin.id)" key="download-success"
                        class="mb-3 p-2 bg-green-100 text-green-700 text-sm rounded flex items-center">
                        <svg class="h-4 w-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"
                            xmlns="http://www.w3.org/2000/svg">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7">
                            </path>
                        </svg>
                        <span>下载成功</span>
                    </div>

                    <div v-else-if="downloadError?.has(plugin.id)" key="download-error"
                        class="mb-3 p-2 bg-red-100 text-red-700 text-sm rounded">
                        <div class="font-semibold mb-1 flex justify-between items-center">
                            <span>下载失败：</span>
                            <div class="flex gap-1">
                                <button @click="copyErrorMessage(downloadError.get(plugin.id))"
                                    class="flex items-center px-2 py-0.5 text-xs bg-red-200 text-red-800 rounded hover:bg-red-300">
                                    <svg class="h-3 w-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                            d="M8 5H6a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2v-1M8 5a2 2 0 002 2h2a2 2 0 002-2M8 5a2 2 0 012-2h2a2 2 0 012 2m0 0h2a2 2 0 012 2v3m2 4H10m0 0l3-3m-3 3l3 3">
                                        </path>
                                    </svg>
                                    复制
                                </button>
                                <button @click="clearDownloadError(plugin.id)"
                                    class="flex items-center px-2 py-0.5 text-xs bg-red-200 text-red-800 rounded hover:bg-red-300 transition-colors">
                                    <svg class="h-3 w-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                            d="M6 18L18 6M6 6l12 12"></path>
                                    </svg>
                                </button>
                            </div>
                            <div class="whitespace-pre-wrap break-words">{{ downloadError.get(plugin.id) }}</div>
                        </div>
                    </div>
                </transition>
            </template>

            <!-- 插件基本信息 -->
            <h3 class="text-lg font-semibold mb-2">{{ plugin.name }}</h3>
            <p class="text-gray-600 text-sm mb-4">{{ plugin.description }}</p>

            <!-- 插件详细信息 -->
            <div class="flex justify-between items-center text-sm">
                <span class="text-gray-500">v{{ plugin.version }}</span>
                <span class="text-gray-500">{{ plugin.author }}</span>
            </div>

            <!-- 插件类型信息 (仅本地插件) -->
            <div v-if="type === 'local'" class="text-xs text-gray-500 mt-2">
                <span class="inline-block mr-2">类型: {{ plugin.type === 'user' ? '已安装' : '开发中' }}</span>
                <span class="inline-block">版本: {{ plugin.version }}</span>
            </div>

            <!-- 操作区域 -->
            <div class="mt-4 flex flex-wrap gap-2 items-center">
                <!-- 本地插件操作 -->
                <template v-if="type === 'local'">
                    <!-- 卸载按钮 (仅用户插件) -->
                    <div v-if="isUserPlugin" class="relative">
                        <!-- 卸载确认界面 -->
                        <transition name="slide-fade">
                            <div v-if="showUninstallConfirm"
                                class="fixed inset-x-0 top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-60 bg-white border border-gray-200 rounded-lg shadow-lg p-4 z-50">
                                <div class="text-sm font-medium mb-3">确定要卸载此插件吗？</div>
                                <div class="flex gap-2">
                                    <button @click="handleUninstall"
                                        class="flex-1 px-3 py-2 text-xs bg-red-500 text-white rounded hover:bg-red-600 transition-colors">
                                        确认卸载
                                    </button>
                                    <button @click="cancelUninstall"
                                        class="flex-1 px-3 py-2 text-xs bg-gray-200 text-gray-700 rounded hover:bg-gray-300 transition-colors">
                                        取消
                                    </button>
                                </div>
                            </div>
                        </transition>

                        <!-- 卸载按钮 -->
                        <transition name="fade" mode="out-in">
                            <button v-if="!uninstallingPlugins?.has(plugin.id) && !isUninstalling"
                                @click="confirmUninstall"
                                class="px-3 py-1 text-sm rounded bg-red-500 text-white hover:bg-red-600 transition-colors focus:outline-none">
                                卸载
                            </button>

                            <button v-else disabled
                                class="px-3 py-1 text-sm rounded bg-gray-300 text-gray-500 cursor-not-allowed focus:outline-none flex items-center">
                                <svg class="animate-spin -ml-1 mr-2 h-3 w-3 text-gray-500"
                                    xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor"
                                        stroke-width="4"></circle>
                                    <path class="opacity-75" fill="currentColor"
                                        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z">
                                    </path>
                                </svg>
                                卸载中...
                            </button>
                        </transition>
                    </div>

                    <!-- 卸载成功提示 -->
                    <transition name="fade">
                        <span v-if="uninstallSuccess?.has(plugin.id)" class="text-xs text-green-500 flex items-center">
                            <svg class="h-3 w-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                    d="M5 13l4 4L19 7"></path>
                            </svg>
                            卸载成功
                        </span>
                    </transition>

                    <!-- 卸载错误提示 -->
                    <transition name="fade">
                        <div v-if="uninstallError?.has(plugin.id)" class="text-xs text-red-500 flex items-center">
                            <span>卸载失败: {{ uninstallError.get(plugin.id) }}</span>
                            <button @click="clearUninstallError(plugin.id)"
                                class="ml-1 text-red-500 hover:text-red-700 transition-colors">
                                <svg class="h-3 w-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                        d="M6 18L18 6M6 6l12 12"></path>
                                </svg>
                            </button>
                        </div>
                    </transition>
                </template>

                <!-- 远程插件操作 -->
                <template v-else>
                    <button @click="handleDownload"
                        :disabled="downloadingPlugins?.has(plugin.id) || isInstalled?.(plugin.id)" :class="[
                            'px-3 py-1 text-sm rounded transition-colors',
                            isInstalled?.(plugin.id)
                                ? 'bg-gray-300 text-gray-600 cursor-not-allowed'
                                : downloadingPlugins?.has(plugin.id)
                                    ? 'bg-blue-300 text-blue-700 cursor-wait'
                                    : 'bg-blue-500 text-white hover:bg-blue-600'
                        ]">
                        {{ isInstalled?.(plugin.id) ? '已安装' : '下载' }}
                    </button>
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
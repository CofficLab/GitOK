<!--
 * StatusBar.vue - 状态栏组件
 * 
 * 这个组件负责显示应用的状态信息：
 * - 显示当前时间
 * - 提供路由导航
 * - 提供插件商店入口
 * 
 * 主要功能：
 * - 实时显示当前时间
 * - 提供首页和插件页面切换
 * - 显示当前页面状态
 * - 打开插件商店
 * 
 * 技术栈：
 * - Vue 3
 * - Pinia (appStore)
 * - TailwindCSS
 * 
 * 注意事项：
 * - 使用 ref 管理时间状态
 * - 组件销毁时清理定时器
 * - 通过 appStore 管理视图状态
 -->

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAppStore } from '@renderer/stores/appStore'

const electronApi = window.electron;
const overlaidApi = electronApi.overlaid;

// 当前时间
const currentTime = ref(new Date().toLocaleTimeString())
let timer: ReturnType<typeof setInterval>

// 被覆盖的应用名称
const overlaidAppName = ref<string | null>(null)
let removeOverlaidAppListener: (() => void) | null = null

const router = useRouter()
const route = useRoute()
const appStore = useAppStore()

// 更新时间
const updateTime = () => {
    currentTime.value = new Date().toLocaleTimeString()
}

// 跳转到首页
const goToHome = () => {
    router.push('/')
    appStore.setView('home')
}

// 跳转到插件商店
const goToPluginStore = () => {
    router.push('/plugins')
    appStore.setView('plugins')
    console.log('状态栏：已更新视图状态为plugins')
}

onMounted(() => {
    // 每秒更新一次时间
    timer = setInterval(updateTime, 1000)

    // 监听被覆盖应用变化
    removeOverlaidAppListener = overlaidApi.onOverlaidAppChanged((app) => {
        overlaidAppName.value = app?.name || null
    })
})

onUnmounted(() => {
    // 清理定时器
    clearInterval(timer)
    // 清理监听器
    if (removeOverlaidAppListener) {
        removeOverlaidAppListener()
    }
})
</script>

<template>
    <div class="flex items-center justify-between px-4 py-2 bg-gray-100 border-t">
        <!-- 导航按钮 -->
        <div class="flex items-center space-x-2">
            <button @click="goToHome"
                :class="['px-3 py-1 rounded text-sm', route.path === '/' ? 'bg-blue-500 text-white' : 'text-gray-600 hover:bg-gray-200']">
                首页
            </button>
            <button @click="goToPluginStore"
                :class="['px-3 py-1 rounded text-sm', route.path === '/plugins' ? 'bg-blue-500 text-white' : 'text-gray-600 hover:bg-gray-200']">
                插件商店
            </button>
        </div>

        <!-- 右侧工具栏 -->
        <div class="flex items-center space-x-4">
            <!-- 被覆盖的应用名称 -->
            <div v-if="overlaidAppName" class="text-sm text-gray-600">
                当前覆盖: {{ overlaidAppName }}
            </div>
            <!-- 时间显示 -->
            <div class="text-sm text-gray-600">
                {{ currentTime }}
            </div>
        </div>
    </div>
</template>
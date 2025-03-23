<!--
 * StatusBar.vue - 状态栏组件
 * 
 * 这个组件负责显示应用的状态信息：
 * - 显示当前时间
 * - 提供导航按钮
 * 
 * 主要功能：
 * - 实时显示当前时间
 * - 提供首页和插件页面切换
 * - 显示当前页面状态
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
import { ref, onMounted, onUnmounted, computed } from 'vue'
import { useAppStore } from '../stores/appStore'
import type { ViewType } from '../stores/appStore'

const currentTime = ref(new Date().toLocaleTimeString())
let timer: ReturnType<typeof setInterval>

const appStore = useAppStore()
const currentView = computed(() => appStore.currentView)

const updateTime = () => {
    currentTime.value = new Date().toLocaleTimeString()
}

const switchView = (view: ViewType) => {
    appStore.setView(view)
}

onMounted(() => {
    // 每秒更新一次时间
    timer = setInterval(updateTime, 1000)
})

onUnmounted(() => {
    // 清理定时器
    clearInterval(timer)
})
</script>

<template>
    <div class="flex items-center justify-between px-4 py-2 bg-gray-100 border-t">
        <!-- 导航按钮 -->
        <div class="flex items-center space-x-2">
            <button @click="switchView('home')"
                :class="['px-3 py-1 rounded text-sm', currentView === 'home' ? 'bg-blue-500 text-white' : 'text-gray-600 hover:bg-gray-200']">
                首页
            </button>
            <button @click="switchView('plugins')"
                :class="['px-3 py-1 rounded text-sm', currentView === 'plugins' ? 'bg-blue-500 text-white' : 'text-gray-600 hover:bg-gray-200']">
                插件
            </button>
        </div>

        <!-- 时间显示 -->
        <div class="text-sm text-gray-600">
            {{ currentTime }}
        </div>
    </div>
</template>
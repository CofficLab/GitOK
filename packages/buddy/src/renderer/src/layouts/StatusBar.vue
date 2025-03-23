<!--
 * StatusBar.vue - 状态栏组件
 * 
 * 这个组件负责显示应用的状态信息：
 * - 显示当前时间
 * - 提供导航按钮
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
import { ref, onMounted, onUnmounted, computed } from 'vue'
import { useAppStore } from '../stores/appStore'
import type { ViewType } from '../stores/appStore'
import PluginStore from '../components/PluginStore.vue'
import StoreIcon from '../components/icons/StoreIcon.vue'

const currentTime = ref(new Date().toLocaleTimeString())
const showPluginStore = ref(false)
let timer: ReturnType<typeof setInterval>

const appStore = useAppStore()
const currentView = computed(() => appStore.currentView)

const updateTime = () => {
    currentTime.value = new Date().toLocaleTimeString()
}

const switchView = (view: ViewType) => {
    appStore.setView(view)
}

const togglePluginStore = () => {
    showPluginStore.value = !showPluginStore.value
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

        <!-- 右侧工具栏 -->
        <div class="flex items-center space-x-4">
            <!-- 插件商店按钮 -->
            <button @click="togglePluginStore"
                class="px-3 py-1 rounded text-sm text-gray-600 hover:bg-gray-200 flex items-center">
                <StoreIcon class="h-4 w-4 mr-1" />
                插件商店
            </button>

            <!-- 时间显示 -->
            <div class="text-sm text-gray-600">
                {{ currentTime }}
            </div>
        </div>
    </div>

    <!-- 插件商店模态框 -->
    <div v-if="showPluginStore" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
        @click.self="showPluginStore = false">
        <div class="bg-base-100 rounded-lg shadow-xl w-3/4 max-w-4xl max-h-[80vh] overflow-y-auto">
            <PluginStore />
        </div>
    </div>
</template>
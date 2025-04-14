<!--
 * StatusBar.vue - 状态栏组件
 * 
 * 这个组件负责显示应用的状态信息：
 * - 显示当前时间
 * - 提供路由导航
 * - 提供插件商店入口
 * - 显示窗口激活状态
 * - 提供打开配置文件夹功能
 -->

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAppStore } from '@renderer/stores/appStore'
import StatusBar from '@renderer/cosy/StatusBar.vue'
import StatusBarItem from '@renderer/cosy/StatusBarItem.vue'
import { ipcApi } from '@renderer/api/ipc-api'

// 当前时间
const currentTime = ref(new Date().toLocaleTimeString())
let timer: ReturnType<typeof setInterval>

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

// 跳转到聊天界面
const goToChat = () => {
    router.push('/chat')
    appStore.setView('chat')
    console.log('状态栏：已更新视图状态为chat')
}

const goToPluginGrid = () => {
    router.push('/plugin-grid')
    appStore.setView('plugin-grid')
}

// 打开配置文件夹
const openConfigFolder = async () => {
    try {
        await ipcApi.openConfigFolder()
        console.log('已打开配置文件夹')
    } catch (error) {
        console.error('打开配置文件夹失败:', error)
    }
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
    <StatusBar>
        <!-- 左侧导航按钮 -->
        <template #left>
            <StatusBarItem clickable @click="goToHome" :active="route.path === '/'"
                :variant="route.path === '/' ? 'primary' : 'default'">
                首页
            </StatusBarItem>
            <StatusBarItem clickable @click="goToPluginStore" :active="route.path === '/plugins'"
                :variant="route.path === '/plugins' ? 'primary' : 'default'">
                插件商店
            </StatusBarItem>
            <StatusBarItem clickable @click="goToChat" :active="route.path === '/chat'"
                :variant="route.path === '/chat' ? 'primary' : 'default'">
                聊天
            </StatusBarItem>
        </template>

        <!-- 右侧状态栏 -->
        <template #right>
            <!-- 配置文件夹按钮 -->
            <StatusBarItem clickable @click="openConfigFolder" title="打开配置文件夹">
                配置
            </StatusBarItem>

            <!-- 被覆盖的应用名称 -->
            <StatusBarItem v-if="appStore.overlaidApp">
                {{ appStore.overlaidApp.name }}
            </StatusBarItem>

            <!-- 时间显示 -->
            <StatusBarItem>
                {{ currentTime }}
            </StatusBarItem>
        </template>
    </StatusBar>
</template>
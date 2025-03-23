<!--
 * TitleBar.vue - 标题栏组件
 * 
 * 这个组件负责显示应用的标题栏：
 * 1. 应用标题
 * 2. 窗口控制按钮
 * 
 * 主要功能：
 * - 显示应用标题
 * - 提供窗口最小化、最大化、关闭按钮
 * - 处理窗口控制事件
 * 
 * 技术栈：
 * - Vue 3
 * - TailwindCSS
 * - Electron IPC
 * 
 * 注意事项：
 * - 窗口控制通过Electron IPC实现
 * - 组件样式遵循系统原生窗口样式
 * - 确保拖拽区域正确设置
 -->

<template>
    <div :class="[
        'fixed top-0 left-0 w-full z-[9999] bg-transparent',
        showTrafficLights ? 'h-7' : 'h-10 pl-4',
    ]" style="-webkit-app-region: drag;">
        <slot></slot>
    </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from "vue"
import { ipcRenderer } from 'electron'

const showTrafficLights = ref(true)

// 监听配置变化
onMounted(() => {
    // 获取初始配置
    // @ts-ignore - 类型错误处理
    window.api.getWindowConfig().then((config) => {
        showTrafficLights.value = config.showTrafficLights
    })

    // 监听配置变化
    // @ts-ignore - 类型错误处理
    const unsubscribe = window.api.onWindowConfigChanged((_, config) => {
        showTrafficLights.value = config.showTrafficLights
    })

    // 清理监听器
    onUnmounted(() => {
        unsubscribe()
    })
})

const minimize = () => {
    ipcRenderer.send('window-minimize')
}

const maximize = () => {
    ipcRenderer.send('window-maximize')
}

const close = () => {
    ipcRenderer.send('window-close')
}
</script>

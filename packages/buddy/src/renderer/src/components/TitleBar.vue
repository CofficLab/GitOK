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
</script>

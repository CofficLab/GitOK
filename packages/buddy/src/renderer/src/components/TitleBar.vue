<template>
    <div class="title-bar" :class="{ 'no-traffic-lights': !showTrafficLights }">
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

<style scoped>
.title-bar {
    -webkit-app-region: drag;
    /* 使区域可拖动 */
    height: 28px;
    /* 标准标题栏高度 */
    width: 100%;
    background: transparent;
    position: fixed;
    top: 0;
    left: 0;
    z-index: 9999;
}

/* 当隐藏红绿灯时，增加左侧边距，避免与内容重叠 */
.title-bar.no-traffic-lights {
    height: 38px;
    /* 稍微增加高度 */
    padding-left: 16px;
}

/* 确保按钮和输入框等元素在标题栏中仍然可以点击 */
.title-bar :deep(*) {
    -webkit-app-region: no-drag;
}
</style>

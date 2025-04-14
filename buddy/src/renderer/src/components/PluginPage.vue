<script setup lang="ts">
import { onMounted, nextTick, ref, onUnmounted } from 'vue'
import { logger } from '../utils/logger'
import { ipcApi } from '../api/ipc-api'
import { SuperPlugin } from '@/types/super_plugin';

interface Props {
    plugin: SuperPlugin
}

const props = defineProps<Props>()

function getPluginViewHeight(originalHeight: number): number {
    return Math.max(originalHeight - 30, 0)
}

const container = ref<HTMLElement | null>(null)

// 定义一个函数用于处理位置变化
const handlePositionChange = () => {
    if (container.value) {
        const rect = container.value.getBoundingClientRect()
        const x = Math.round(rect.x)
        const y = Math.round(rect.y)
        logger.info(`PluginView: container 的 x 坐标: ${x}, y 坐标: ${y}`)

        const options = {
            x: Math.round(rect.x),
            y: Math.round(rect.y),
            width: Math.round(rect.width),
            height: getPluginViewHeight(Math.round(rect.height)),
            pagePath: props.plugin.pagePath,
        }

        ipcApi.updateViewBounds(props.plugin.pagePath!, options)
    }
}

onMounted(async () => {
    await nextTick()

    if (!container.value) {
        logger.error(`PluginView: 未找到插件视图容器元素: ${props.plugin.id}`)
        return
    }

    const rect = container.value.getBoundingClientRect()
    const options = {
        x: Math.round(rect.x),
        y: Math.round(rect.y),
        width: Math.round(rect.width),
        height: getPluginViewHeight(Math.round(rect.height)),
        pagePath: props.plugin.pagePath,
    }

    logger.info('PluginView: 创建插件视图', options)
    await ipcApi.createView(options)

    // 创建 ResizeObserver 监听元素大小变化
    const resizeObserver = new ResizeObserver(handlePositionChange)
    resizeObserver.observe(container.value)

    // 创建 IntersectionObserver 监听元素进入或离开视口
    const intersectionObserver = new IntersectionObserver(handlePositionChange)
    intersectionObserver.observe(container.value)

    // 监听窗口滚动事件
    const handleScroll = (event) => {
        logger.info('PluginView: 窗口滚动', event.detail)
        handlePositionChange()
    }
    document.addEventListener('content-scroll', handleScroll)

    // 在组件卸载时移除监听
    onUnmounted(() => {
        resizeObserver.disconnect()
        intersectionObserver.disconnect()
        window.removeEventListener('scroll', handleScroll)
    })
})
</script>

<template>
    <div class="h-48 w-full bg-gray-100 rounded-lg" ref="container"></div>
</template>
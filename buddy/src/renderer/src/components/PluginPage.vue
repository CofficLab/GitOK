<script setup lang="ts">
import { onMounted, onUnmounted, nextTick, ref } from 'vue'
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

const observer = ref<IntersectionObserver | null>(null)
const container = ref<HTMLElement | null>(null)

onMounted(async () => {
    await nextTick()

    if (!container.value) {
        logger.error(`PluginView: 未找到插件视图容器元素: ${props.plugin.id}`)
        return
    }

    const rect = container.value.getBoundingClientRect()
    await ipcApi.createView({
        x: Math.round(rect.x),
        y: Math.round(rect.y),
        width: Math.round(rect.width),
        height: getPluginViewHeight(Math.round(rect.height)),
        pagePath: props.plugin.pagePath,
    })

    observer.value = new IntersectionObserver((entries) => {
        entries.forEach(async (entry) => {
            const rect = entry.boundingClientRect
            const intersectionRect = entry.intersectionRect

            await ipcApi.updateViewBounds(props.plugin.pagePath ?? "wild", {
                x: Math.round(rect.x),
                y: Math.round(rect.y),
                width: Math.round(intersectionRect.width),
                height: getPluginViewHeight(Math.round(intersectionRect.height)),
            })
        })
    }, {
        threshold: [0, 0.25, 0.5, 0.75, 1]
    })

    observer.value.observe(container.value)
})

onUnmounted(() => {
    if (observer.value) {
        observer.value.disconnect()
        observer.value = null
    }
})
</script>

<template>
    <div class="h-48 w-full bg-gray-100 rounded-lg" ref="container"></div>
</template>
<script setup lang="ts">
import { onMounted, nextTick, ref, onUnmounted, watch } from 'vue'
import { logger } from '../utils/logger'
import { viewIpc } from '../api/view-ipc'
import { SuperPlugin } from '@/types/super_plugin';
import { createViewArgs } from '@/types/args';

interface Props {
    plugin: SuperPlugin
}

const props = defineProps<Props>()
const options = ref<createViewArgs | null>(null)

const container = ref<HTMLElement | null>(null)

// 定义一个函数用于处理位置变化
const handlePositionChange = () => {
    if (container.value) {
        const rect = container.value.getBoundingClientRect()

        options.value = {
            x: Math.round(rect.x),
            y: Math.round(rect.y),
            width: Math.round(rect.width),
            height: Math.round(rect.height),
            pagePath: props.plugin.pagePath,
        }
    }
}

onMounted(async () => {
    await nextTick()

    if (!container.value) {
        logger.error(`PluginView: 未找到插件视图容器元素: ${props.plugin.id}`)
        return
    }

    const rect = container.value.getBoundingClientRect()
    options.value = {
        x: Math.round(rect.x),
        y: Math.round(rect.y),
        width: Math.round(rect.width),
        height: Math.round(rect.height),
        pagePath: props.plugin.pagePath,
    }

    document.addEventListener('content-scroll', handlePositionChange)
})

onUnmounted(() => {
    document.removeEventListener('content-scroll', handlePositionChange)
})

watch(options, () => {
    if (options.value == null) return
    viewIpc.upsertView(props.plugin.pagePath!, {
        x: options.value.x,
        y: options.value.y,
        width: options.value.width,
        height: options.value.height,
    })
}, { immediate: true })
</script>

<template>
    <div class="h-56 w-full" ref="container"></div>
</template>
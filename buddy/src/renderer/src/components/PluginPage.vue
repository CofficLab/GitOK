<script setup lang="ts">
import { watch, ref, onUnmounted, onMounted, nextTick } from 'vue'
import { useElementBounding, useMutationObserver } from '@vueuse/core'
import { viewIpc } from '../ipc/view-ipc'
import { SendablePlugin } from '@/types/sendable-plugin';
import { createViewArgs } from '@/types/args';

interface Props {
    plugin: SendablePlugin
}

const props = defineProps<Props>()
const container = ref<HTMLElement | null>(null)

// 使用useElementBounding自动监听元素位置变化，但设置immediate为false，避免过早获取位置
const { x, y, width, height, update } = useElementBounding(container, { immediate: false })

// 创建计算后的位置参数
const options = ref<createViewArgs | null>(null)

// 监听DOM变化
useMutationObserver(
    document.body,
    () => {
        // 当DOM变化时更新位置
        if (container.value) update()
    },
    { childList: true, subtree: true }
)

// 手动更新位置信息
const updatePosition = async () => {
    await nextTick()
    if (!container.value) return

    // 强制更新位置
    update()

    // 确保更新后使用最新数据
    setTimeout(() => {
        updateOptions()
    }, 10)
}

// 更新选项
const updateOptions = () => {
    const pagePath = props.plugin.pagePath
    if (!pagePath || !container.value) return

    options.value = {
        x: Math.round(x.value),
        y: Math.round(y.value),
        width: Math.round(width.value),
        height: Math.round(height.value),
        pagePath,
    }
}

// 当位置变化时更新options
watch([x, y, width, height], updateOptions, { immediate: true })

// 监听content-scroll事件时手动触发位置更新
const handlePositionChange = () => {
    update()
}

onMounted(async () => {
    // 在挂载和nextTick后执行初始更新
    await nextTick()
    update()

    // 额外添加一个延时更新，确保页面完全渲染（包括可能的异步内容）后再次获取位置
    setTimeout(updatePosition, 100)

    // 添加自定义滚动事件监听
    document.addEventListener('content-scroll', handlePositionChange)
})

// 组件卸载时移除事件监听
onUnmounted(() => {
    document.removeEventListener('content-scroll', handlePositionChange)
})

// 监听options变化并更新视图
watch(options, () => {
    if (options.value == null) return

    viewIpc.upsertView({
        pagePath: props.plugin.pagePath!,
        x: options.value.x,
        y: options.value.y,
        width: options.value.width,
        height: options.value.height,
    })
}, { immediate: false })
</script>

<template>
    <div class="h-56 w-full" ref="container"></div>
</template>
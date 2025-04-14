<script setup lang="ts">
import { useMarketStore } from '../stores/marketStore'
import { onMounted, onUnmounted, nextTick, computed, ref } from 'vue'
import { logger } from '../utils/logger'
import { ipcApi } from '../api/ipc-api'

const marketStore = useMarketStore()
const plugins = computed(() => marketStore.pluginsWithPage)

function getPluginViewHeight(originalHeight: number): number {
  return Math.max(originalHeight - 30, 0)
}

const observer = ref<IntersectionObserver | null>(null)

onMounted(async () => {
  logger.info('加载插件视图, 插件数量: ', plugins.value.length)

  // 创建插件视图
  await createPluginViews()

  // 创建IntersectionObserver
  observer.value = new IntersectionObserver((entries) => {
    entries.forEach(async (entry) => {
      const plugin = plugins.value.find(p => `plugin-view-${p.id}` === entry.target.id)
      if (!plugin) return

      const rect = entry.boundingClientRect
      const intersectionRect = entry.intersectionRect

      await ipcApi.updateViewBounds(plugin.pagePath ?? "wild", {
        x: Math.round(rect.x),
        y: Math.round(rect.y),
        width: Math.round(intersectionRect.width),
        height: getPluginViewHeight(Math.round(intersectionRect.height)),
      })
    })
  }, {
    threshold: [0, 0.25, 0.5, 0.75, 1]
  })

  // 观察所有插件容器
  plugins.value.forEach(plugin => {
    const container = document.getElementById(`plugin-view-${plugin.id}`)
    if (container) {
      observer.value?.observe(container)
    }
  })
})

// 创建插件视图
const createPluginViews = async () => {
  for (const plugin of plugins.value) {
    await nextTick()

    const container = document.getElementById(`plugin-view-${plugin.id}`)
    if (!container) {
      logger.error(`PluginView: 未找到插件视图容器元素: ${plugin.id}`)
      continue
    }

    const rect = container.getBoundingClientRect()
    await ipcApi.createView({
      x: Math.round(rect.x),
      y: Math.round(rect.y),
      width: Math.round(rect.width),
      height: getPluginViewHeight(Math.round(rect.height)),
      pagePath: plugin.pagePath,
    })
  }
}

onUnmounted(() => {
  logger.info('PluginView: 卸载插件视图')

  // 断开所有观察
  if (observer.value) {
    observer.value.disconnect()
    observer.value = null
  }

  ipcApi.destroyPluginViews()
})
</script>

<template>
  <div class="w-full h-full flex flex-col overflow-hidden px-4 bg-amber-100">
    <div class="flex-1 overflow-auto">
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 p-4">
        <div v-for="(plugin, index) in plugins" :key="index" class="bg-white rounded-lg shadow-md p-4">
          <div class="h-96 w-full bg-gray-100 rounded-lg" :id="`plugin-view-${plugin.id}`"></div>
        </div>
      </div>
    </div>
  </div>
</template>
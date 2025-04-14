<script setup lang="ts">
import { useMarketStore } from '../stores/marketStore'
import { onMounted, onUnmounted, nextTick, computed } from 'vue'
import { logger } from '../utils/logger'
import { ipcApi } from '../api/ipc-api'

const marketStore = useMarketStore()
const plugins = computed(() => marketStore.pluginsWithPage)

onMounted(async () => {
  logger.info('加载插件视图, 插件数量: ', plugins.value.length)

  plugins.value.forEach(async (plugin) => {
    // 等待DOM更新完成
    await nextTick()

    // 获取插件视图容器元素
    const container = document.getElementById(`plugin-view-${plugin.id}`)

    logger.info('PluginView: 插件视图容器元素: ', container)

    if (!container) {
      logger.error(`PluginView: 未找到插件视图容器元素: ${plugin.id}`)
      return
    }

    // 获取容器元素的位置和大小信息
    const rect = container.getBoundingClientRect()
    // 创建插件视图并传递位置信息
    await ipcApi.createView({
      x: Math.round(rect.x),
      y: Math.round(rect.y),
      width: Math.round(rect.width),
      height: Math.round(rect.height),
      pagePath: plugin.pagePath,
    })
  })
})

onUnmounted(() => {
  logger.info('PluginView: 卸载插件视图')

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
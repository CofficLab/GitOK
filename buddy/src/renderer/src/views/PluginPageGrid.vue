<script setup lang="ts">
import { useMarketStore } from '../stores/marketStore'
import { useAlert } from '../composables/useAlert'
import { onMounted, onUnmounted, nextTick, ref } from 'vue'
import { logger } from '../utils/logger'
import { ipcApi } from '../api/ipc-api'

const marketStore = useMarketStore()
const alert = useAlert()
const plugins = marketStore.devPlugins
const pluginsWithPage = plugins.filter((p) => p.hasPage)

// 存储已创建的视图路径
const createdViews = ref<Set<string>>(new Set())

onMounted(async () => {
  pluginsWithPage.forEach(async (plugin) => {
    // 等待DOM更新完成
    await nextTick()

    // 获取插件视图容器元素
    const container = document.getElementById(`plugin-view-${plugin.id}`)
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
    // 记录已创建的视图路径
    createdViews.value.add(plugin.pagePath ?? "wild")
  })
})

onUnmounted(() => {
  // 销毁所有已创建的视图
  createdViews.value.forEach(async pagePath => {
    try {
      await ipcApi.destroyView(pagePath)
    } catch (e) {
      alert.error(`PluginView: 销毁视图失败: ${pagePath}`)
    }
  })
  createdViews.value.clear()
})
</script>

<template>
  <div class="w-full h-full flex flex-col overflow-hidden px-4">
    <div class="flex-1 overflow-auto">
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 p-4">
        <div v-for="(plugin, index) in pluginsWithPage" :key="index" class="bg-white rounded-lg shadow-md p-4">
          <div class="h-96 w-full bg-gray-100 rounded-lg" :id="`plugin-view-${plugin.id}`"></div>
        </div>
      </div>
    </div>
  </div>
</template>
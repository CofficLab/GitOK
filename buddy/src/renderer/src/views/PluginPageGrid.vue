<script setup lang="ts">
import { useMarketStore } from '../stores/marketStore'
import { onUnmounted, computed } from 'vue'
import { logger } from '../utils/logger'
import { ipcApi } from '../api/ipc-api'
import PluginPage from '../components/PluginPage.vue'

const marketStore = useMarketStore()
const plugins = computed(() => marketStore.pluginsWithPage)

onUnmounted(() => {
  logger.info('PluginView: 卸载插件视图')
  ipcApi.destroyPluginViews()
})
</script>

<template>
  <div class="w-full h-96 flex flex-col overflow-hidden px-4 bg-amber-100">
    <div class="flex-1">
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 p-4">
        <div v-for="(plugin, index) in plugins" :key="index" class="bg-white rounded-lg shadow-md p-4">
          <PluginPage :plugin="plugin" />
        </div>
      </div>
    </div>
  </div>
</template>
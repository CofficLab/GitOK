<script setup lang="ts">
import { useMarketStore } from '../stores/marketStore'
import { onUnmounted, computed } from 'vue'
import { logger } from '../utils/logger'
import { viewIpc } from '../ipc/view-ipc'
import PluginPage from '../components/PluginPage.vue'

const marketStore = useMarketStore()
const plugins = computed(() => marketStore.pluginsWithPage)

onUnmounted(() => {
    logger.info('PluginView: 卸载插件视图')
    viewIpc.destroyViews()
})
</script>

<template>
    <div class="w-full h-full flex flex-col overflow-hidden bg-amber-100/0">
        <div class="flex-1">
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                <div v-for="(plugin, index) in plugins" :key="index">
                    <PluginPage :plugin="plugin" />
                </div>
            </div>
        </div>
    </div>
</template>
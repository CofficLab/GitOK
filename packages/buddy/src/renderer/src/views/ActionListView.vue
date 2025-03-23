/**
* 插件动作列表视图
*
* 功能：
* 1. 展示可用的插件动作列表
* 2. 处理动作选择事件
* 3. 支持搜索结果展示
*/
<script setup lang="ts">
import { onMounted, ref, computed, watch } from 'vue'
import { useSearchStore } from '@renderer/stores/searchStore'
import PluginActionList from '@renderer/components/PluginActionList.vue'
import type { PluginAction } from '@renderer/components/PluginManager.vue'

const searchStore = useSearchStore()
const logMessages = ref<string[]>([])
const isDev = process.env.NODE_ENV !== 'production'

// 记录调试消息
const logDebug = (message: string) => {
    console.log(`ActionListView: ${message}`)
    logMessages.value.push(message)

    // 限制日志数量
    if (logMessages.value.length > 10) {
        logMessages.value.shift()
    }
}

// 处理动作选择
const handleActionSelected = (action: PluginAction) => {
    logDebug(`选择动作: ${action.title}`)
    searchStore.selectAction(action.id)
}

// 检查动作列表状态
const hasActions = computed(() => searchStore.pluginActions.length > 0)
const hasKeyword = computed(() => searchStore.keyword.length > 0)
const isLoading = computed(() => searchStore.isLoading)

// 组件挂载时的初始化
onMounted(() => {
    logDebug('ActionListView 已挂载')
    logDebug(`当前搜索状态: keyword="${searchStore.keyword}", actions=${searchStore.pluginActions.length}`)

    // 初始化时加载插件动作（如果尚未加载且不在加载中）
    if (searchStore.pluginActions.length === 0 && !searchStore.isLoading) {
        logDebug('自动加载插件动作')
        searchStore.loadPluginActions()
    }

    // 立即检查一下搜索状态
    checkAndDebugState()
})

// 监听搜索关键词的变化
watch(() => searchStore.keyword, (newKeyword) => {
    logDebug(`ActionListView: 搜索关键词变化为 "${newKeyword}"`)
    checkAndDebugState()
})

// 监听动作列表的变化
watch(() => searchStore.pluginActions, (actions) => {
    logDebug(`ActionListView: 动作列表已更新，当前有 ${actions.length} 个动作`)
    checkAndDebugState()
}, { deep: true })

// 用于调试当前状态
const checkAndDebugState = () => {
    logDebug(`
    -----------状态检查------------
    当前关键词: "${searchStore.keyword}"
    动作数量: ${searchStore.pluginActions.length}
    是否加载中: ${searchStore.isLoading}
    hasActions: ${hasActions.value}
    hasKeyword: ${hasKeyword.value}
    --------------------------------
    `)
}
</script>

<template>
    <div class="action-list-view">
        <h2 class="text-xl font-semibold mb-4">可用动作</h2>

        <div v-if="logMessages.length > 0 && isDev"
            class="debug-log mb-4 p-2 bg-gray-100 text-xs text-gray-600 rounded">
            <div v-for="(msg, index) in logMessages" :key="index" class="debug-message">
                {{ msg }}
            </div>
        </div>

        <!-- 显示当前搜索状态 -->
        <div class="search-info mb-2 text-sm text-gray-500">
            <div v-if="hasKeyword">当前搜索: {{ searchStore.keyword }}</div>
            <div v-if="hasActions">找到 {{ searchStore.pluginActions.length }} 个动作</div>
        </div>

        <PluginActionList :actions="searchStore.pluginActions" :loading="searchStore.isLoading"
            @select="handleActionSelected" @cancel="searchStore.clearSearch()" />

        <!-- 空状态提示 -->
        <div v-if="!isLoading && !hasActions && hasKeyword" class="empty-state mt-4 p-4 bg-gray-50 rounded text-center">
            <p class="text-gray-500">没有找到匹配 "{{ searchStore.keyword }}" 的动作</p>
            <p class="text-gray-400 text-sm mt-2">尝试其他关键词或安装更多插件</p>
        </div>
    </div>
</template>

<style scoped>
.action-list-view {
    padding: 1rem 0;
}

.debug-log {
    font-family: monospace;
    max-height: 150px;
    overflow-y: auto;
}

.empty-state {
    border: 1px dashed #ccc;
}
</style>
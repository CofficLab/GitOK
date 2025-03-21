<script setup lang="ts">
import { computed, defineProps, defineEmits } from 'vue'

// 插件动作类型定义
interface PluginAction {
    id: string
    title: string
    description: string
    icon: string
    plugin: string
}

const props = defineProps<{
    actions: PluginAction[]
    searchKeyword: string
}>()

const emit = defineEmits<{
    (e: 'execute', action: PluginAction): void
}>()

// 搜索结果
const searchResults = computed(() => {
    if (!props.searchKeyword) {
        // 无输入时显示最常用的几个动作
        return props.actions.slice(0, 5)
    }

    // 关键字搜索逻辑
    const keyword = props.searchKeyword.toLowerCase()
    return props.actions
        .filter(action => {
            return action.title.toLowerCase().includes(keyword) ||
                action.description.toLowerCase().includes(keyword) ||
                action.plugin.toLowerCase().includes(keyword)
        })
        .sort((a, b) => {
            // 标题匹配的优先级最高
            const aInTitle = a.title.toLowerCase().includes(keyword)
            const bInTitle = b.title.toLowerCase().includes(keyword)

            if (aInTitle && !bInTitle) return -1
            if (!aInTitle && bInTitle) return 1

            // 其次是插件名称匹配
            const aInPlugin = a.plugin.toLowerCase().includes(keyword)
            const bInPlugin = b.plugin.toLowerCase().includes(keyword)

            if (aInPlugin && !bInPlugin) return -1
            if (!aInPlugin && bInPlugin) return 1

            return 0
        })
})

// 执行插件动作
const executeAction = (action: PluginAction) => {
    emit('execute', action)
}
</script>

<template>
    <div class="results-container flex-1 overflow-y-auto mb-4 rounded-lg border border-base-300">
        <ul class="menu bg-base-200 rounded-lg">
            <li v-for="result in searchResults" :key="result.id" @click="executeAction(result)">
                <a class="flex items-center p-3 hover:bg-base-300 focus:bg-base-300 outline-none">
                    <i :class="result.icon" class="text-2xl mr-3"></i>
                    <div class="flex-1">
                        <div class="font-medium">{{ result.title }}</div>
                        <div class="text-sm opacity-70">{{ result.description }}</div>
                    </div>
                    <span class="badge badge-sm">{{ result.plugin }}</span>
                </a>
            </li>
            <li v-if="searchResults.length === 0" class="p-4 text-center text-base-content/50">
                没有找到匹配的结果
            </li>
        </ul>
    </div>
</template>

<style scoped>
.results-container {
    max-height: calc(100vh - 180px);
    /* 调整以适应搜索框和状态栏 */
}
</style>
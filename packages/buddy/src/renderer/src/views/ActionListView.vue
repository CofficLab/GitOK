/**
* 插件动作列表视图
*
* 功能：
* 1. 展示可用的插件动作列表
* 2. 处理动作选择事件
* 3. 支持搜索结果展示
* 4. 支持键盘导航
*/
<script setup lang="ts">
import { onMounted, computed } from 'vue'
import { useSearchStore } from '@renderer/stores/searchStore'
import type { PluginAction } from '@renderer/components/PluginManager.vue'

const searchStore = useSearchStore()

// 处理动作选择
const handleActionSelected = (action: PluginAction) => {
    searchStore.selectAction(action.id)
}

// 处理取消操作
const handleCancel = () => {
    searchStore.clearSearch()
}

// 检查动作列表状态
const hasActions = computed(() => searchStore.pluginActions.length > 0)
const hasKeyword = computed(() => searchStore.keyword.length > 0)
const isLoading = computed(() => searchStore.isLoading)

// 组件挂载时的初始化
onMounted(() => {
    // 初始化时加载插件动作（如果尚未加载且不在加载中）
    if (searchStore.pluginActions.length === 0 && !searchStore.isLoading) {
        searchStore.loadPluginActions()
    }
})
</script>

<template>
    <div class="action-list-view">
        <h2 class="text-xl font-semibold mb-4">可用动作</h2>

        <!-- 显示当前搜索状态 -->
        <div class="search-info mb-2 text-sm text-gray-500">
            <div v-if="hasKeyword">当前搜索: {{ searchStore.keyword }}</div>
            <div v-if="hasActions">找到 {{ searchStore.pluginActions.length }} 个动作</div>
        </div>

        <div>
            <!-- 加载状态 -->
            <div v-if="isLoading" class="text-center py-4 text-gray-500">
                <p>加载中...</p>
            </div>

            <!-- 空状态 -->
            <div v-else-if="searchStore.pluginActions.length === 0" class="text-center py-8 text-gray-500">
                <p>没有找到匹配的动作</p>
                <p class="text-sm mt-2">尝试其他关键词或安装更多插件</p>
            </div>

            <!-- 动作列表 -->
            <ul v-else class="space-y-2">
                <li v-for="(result, index) in searchStore.pluginActions" :key="result.id"
                    class="plugin-action-item p-3 border rounded-lg hover:bg-gray-50 cursor-pointer transition-colors flex items-center"
                    :tabindex="index + 1" @click="handleActionSelected(result)"
                    @keydown.enter="handleActionSelected(result)" @keydown.space.prevent="handleActionSelected(result)"
                    @keydown.esc="handleCancel" @keydown.up="index > 0 ? $el.previousElementSibling?.focus() : null"
                    @keydown.down="index < searchStore.pluginActions.length - 1 ? $el.nextElementSibling?.focus() : null">
                    <div v-if="result.icon" class="mr-3 text-xl">{{ result.icon }}</div>
                    <div class="flex-1">
                        <h3 class="font-medium">{{ result.title }}</h3>
                        <p v-if="result.description" class="text-sm text-gray-600">{{ result.description }}</p>
                        <p class="text-xs text-gray-400 mt-1">来自: {{ result.plugin }}</p>
                    </div>
                </li>
            </ul>
        </div>
    </div>
</template>

<style scoped>
.action-list-view {
    padding: 1rem 0;
}

.empty-state {
    border: 1px dashed #ccc;
}

.plugin-action-item:focus {
    outline: 2px solid #4299e1;
    background-color: #ebf8ff;
}
</style>
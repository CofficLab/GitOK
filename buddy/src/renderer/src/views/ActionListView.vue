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
import { computed, watch } from 'vue'
import { useSearchStore } from '@renderer/stores/searchStore'
import type { PluginAction } from '@/types/plugin-action'
import { useActionStore } from '@renderer/stores/actionStore'

const searchStore = useSearchStore()
const actionStore = useActionStore()

// 处理动作选择
const handleActionSelected = (action: PluginAction) => {
    console.log('handleActionSelected 🍋', action.id);
    actionStore.selectAction(action.id)
}

// 处理取消操作
const handleCancel = () => {
    searchStore.clearSearch()
}

// 检查动作列表状态
const hasActions = computed(() => actionStore.getActionCount() > 0)
const hasKeyword = computed(() => searchStore.keyword.length > 0)
const isLoading = computed(() => actionStore.isLoading)


// 监听搜索输入变化，加载相应的插件动作
watch(() => searchStore.keyword, async (newKeyword) => {
    console.log(`ActionListView.vue: 搜索关键词变化为 "${newKeyword}"`);

    // 重新加载插件动作
    try {
        console.log('ActionListView.vue: 开始加载插件动作...');
        await actionStore.loadList();
        console.log(`ActionListView.vue: 插件动作加载完成，共 ${actionStore.getActionCount()} 个`);
    } catch (error) {
        console.error('ActionListView.vue: 加载插件动作失败', error);
    }
}, { immediate: true })
</script>

<template>
    <div class="action-list-view">
        <h2 class="text-xl font-semibold mb-4">可用动作</h2>

        <!-- 显示当前搜索状态 -->
        <div class="search-info mb-2 text-sm text-gray-500">
            <div v-if="hasKeyword">当前搜索: {{ searchStore.keyword }}</div>
            <div v-if="hasActions">找到 {{ actionStore.getActionCount() }} 个动作</div>
        </div>

        <div>
            <!-- 加载状态 -->
            <div v-if="isLoading" class="text-center py-4 text-gray-500">
                <p>加载中...</p>
            </div>

            <!-- 空状态 -->
            <div v-else-if="actionStore.getActionCount() === 0" class="text-center py-8 text-gray-500">
                <p>没有找到匹配的动作</p>
                <p class="text-sm mt-2">尝试其他关键词或安装更多插件</p>
            </div>

            <!-- 动作列表 -->
            <ul v-else class="space-y-2">
                <li v-for="(action, index) in actionStore.getActions()" :key="action.id"
                    class="plugin-action-item p-3 border rounded-lg hover:bg-gray-50 cursor-pointer transition-colors flex items-center"
                    :tabindex="index + 1" @click="handleActionSelected(action)"
                    @keydown.enter="handleActionSelected(action)" @keydown.space.prevent="handleActionSelected(action)"
                    @keydown.esc="handleCancel" @keydown.up="index > 0 ? $el.previousElementSibling?.focus() : null"
                    @keydown.down="index < actionStore.getActionCount() - 1 ? $el.nextElementSibling?.focus() : null">
                    <div v-if="action.icon" class="mr-3 text-xl">{{ action.icon }}</div>
                    <div class="flex-1">
                        <h3 class="font-medium">{{ action.title }}</h3>
                        <p v-if="action.description" class="text-sm text-gray-600">{{ action.description }}</p>
                        <p class="text-xs text-gray-400 mt-1">来自: {{ action.id }}</p>
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
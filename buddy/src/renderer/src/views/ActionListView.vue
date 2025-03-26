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
import { computed, watch, ref } from 'vue'
import ActionItem from '@renderer/components/ActionItem.vue'
import type { SuperAction } from '@/types/super_action'
import { useActionStore } from '@renderer/stores/actionStore'
import { logger } from '@renderer/utils/logger'

const actionStore = useActionStore()
const activeItemIndex = ref(-1)

// 处理动作选择
const handleActionSelected = (action: SuperAction) => {
    logger.info('handleActionSelected 🍋', action.globalId);
    actionStore.selectAction(action.globalId)
}

// 处理取消操作
const handleCancel = () => {
    actionStore.clearSearch()
}

// 检查动作列表状态
const isLoading = computed(() => actionStore.isLoading)

// 处理向上导航
const handleNavigateUp = (index: number) => {
    if (index > 0) {
        activeItemIndex.value = index - 1
        const elements = document.querySelectorAll('.plugin-action-item')
        if (elements[index - 1]) {
            (elements[index - 1] as HTMLElement).focus()
        }
    }
}

// 处理向下导航
const handleNavigateDown = (index: number) => {
    const totalItems = actionStore.getActionCount()
    if (index < totalItems - 1) {
        activeItemIndex.value = index + 1
        const elements = document.querySelectorAll('.plugin-action-item')
        if (elements[index + 1]) {
            (elements[index + 1] as HTMLElement).focus()
        }
    }
}

// 监听搜索输入变化，加载相应的插件动作
watch(() => actionStore.keyword, async (newKeyword) => {
    logger.info(`ActionListView.vue: 搜索关键词变化为 "${newKeyword}"`);

    // 重新加载插件动作
    try {
        await actionStore.loadList();
    } catch (error) {
        logger.error('ActionListView.vue: 加载插件动作失败', error);
    }
}, { immediate: true })
</script>

<template>
    <div class="action-list-view">
        <div>
            <!-- 加载状态 -->
            <div v-if="isLoading" class="text-center py-4 text-base-content/60">
                <p>加载中...</p>
            </div>

            <!-- 空状态 -->
            <div v-else-if="actionStore.getActionCount() === 0" class="text-center py-8 text-base-content/60">
                <p>没有找到匹配的动作</p>
                <p class="text-sm mt-2">尝试其他关键词或安装更多插件</p>
            </div>

            <!-- 动作列表 -->
            <ul v-else class="space-y-2">
                <ActionItem v-for="(action, index) in actionStore.getActions()" :key="action.id" :action="action"
                    :index="index" :total-count="actionStore.getActionCount()" @select="handleActionSelected"
                    @cancel="handleCancel" @navigate-up="handleNavigateUp(index)"
                    @navigate-down="handleNavigateDown(index)" />
            </ul>
        </div>
    </div>
</template>

<style scoped>
.action-list-view {
    padding: 1rem 0;
}

.empty-state {
    border: 1px dashed var(--base-content/30);
}
</style>
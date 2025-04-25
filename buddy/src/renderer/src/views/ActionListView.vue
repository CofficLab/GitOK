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
import { watch, ref, nextTick } from 'vue'
import ActionItem from '@/renderer/src/components/ActionItem.vue'
import { useActionStore } from '@renderer/stores/actionStore'
import { logger } from '@renderer/utils/logger'
import { useAsyncState } from '@vueuse/core'

const actionStore = useActionStore()
const activeItemIndex = ref(-1)
const actionListRef = ref<HTMLElement | null>(null)

// 处理取消操作
const handleCancel = () => {
    actionStore.clearSearch()
}

// 异步加载数据
const { isLoading } = useAsyncState(
    async () => {
        try {
            await actionStore.loadList()
            return true
        } catch (error) {
            logger.error('ActionListView.vue: 加载插件动作失败', error)
            return false
        }
    },
    false,
    { immediate: true }
)

// 设置焦点到指定索引的元素
const focusItemAtIndex = async (index: number) => {
    activeItemIndex.value = index
    await nextTick()

    // 使用传统DOM方法获取元素（已经有类名了）
    const elements = document.querySelectorAll('.plugin-action-item')
    if (elements[index]) {
        const element = elements[index] as HTMLElement
        element.focus()
    }
}

// 处理向上导航
const handleNavigateUp = (index: number) => {
    if (index > 0) {
        focusItemAtIndex(index - 1)
    }
}

// 处理向下导航
const handleNavigateDown = (index: number) => {
    const totalItems = actionStore.getActionCount()
    if (index < totalItems - 1) {
        focusItemAtIndex(index + 1)
    }
}

// 监听搜索输入变化，加载相应的插件动作
watch(() => actionStore.keyword, async () => {
    // 重置选中项索引
    activeItemIndex.value = -1

    try {
        await actionStore.loadList()
    } catch (error) {
        logger.error('ActionListView.vue: 加载插件动作失败', error)
    }
})
</script>

<template>
    <div class="action-list-view" ref="actionListRef">
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
                    :index="index" @cancel="handleCancel" @navigate-up="handleNavigateUp(index)"
                    @navigate-down="handleNavigateDown(index)" class="plugin-action-item" />
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
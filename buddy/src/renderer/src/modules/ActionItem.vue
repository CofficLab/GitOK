/**
* 插件动作项组件 - Raycast UI 风格
*
* 功能：
* 1. 展示单个插件动作的信息
* 2. 处理动作的选择事件
* 3. 支持键盘导航
*/
<script setup lang="ts">
import type { SuperAction } from '@/types/super_action'
import ListItem from '@renderer/cosy/ListItem.vue'

const props = defineProps<{
    action: SuperAction
    index: number
    totalCount: number
}>()

const emit = defineEmits<{
    (e: 'select', action: SuperAction): void
    (e: 'cancel'): void
    (e: 'navigateUp'): void
    (e: 'navigateDown'): void
}>()

// 处理动作选择
const handleSelect = () => {
    emit('select', props.action)
}

// 处理取消操作
const handleCancel = () => {
    emit('cancel')
}

// 处理键盘导航
const handleKeyDown = (event: KeyboardEvent) => {
    switch (event.key) {
        case 'Enter':
        case ' ': // 空格键
            event.preventDefault()
            handleSelect()
            break
        case 'Escape':
            handleCancel()
            break
        case 'ArrowUp':
            emit('navigateUp')
            break
        case 'ArrowDown':
            emit('navigateDown')
            break
    }
}
</script>

<template>
  <ListItem
  bg-color="success"
    :title="action.title"
    :description="action.description"
    :icon="action.icon"
    :tabindex="index + 1"
    @click="handleSelect"
    @keydown="handleKeyDown"
  />
</template>
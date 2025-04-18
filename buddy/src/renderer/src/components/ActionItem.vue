<script setup lang="ts">
import { SendableAction } from '@/types/sendable-action.js';
import ListItem from '@renderer/cosy/ListItem.vue'
import { logger } from '../utils/logger';
import { useActionStore } from '@renderer/stores/actionStore';

const actionStore = useActionStore()
const props = defineProps<{
    action: SendableAction
    index: number
}>()

const emit = defineEmits<{
    (e: 'select', action: SendableAction): void
    (e: 'cancel'): void
    (e: 'navigateUp'): void
    (e: 'navigateDown'): void
}>()

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

// 处理动作选择
const handleSelect = () => {
    logger.info('handleActionSelected 🍋', props.action.globalId);
    actionStore.selectAction(props.action.globalId)
}
</script>

<template>
    <ListItem bg-color="success" :description="action.description" :icon="action.icon" :tabindex="index + 1"
        @click="handleSelect" @keydown="handleKeyDown" />
</template>
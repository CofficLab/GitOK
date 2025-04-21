<script setup lang="ts">
import { SendableAction } from '@/types/sendable-action.js';
import ListItem from '@renderer/cosy/ListItem.vue'
import { logger } from '../utils/logger';
import { useActionStore } from '@renderer/stores/actionStore';
import { computed } from 'vue';

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

const selected = computed(() => {
    return actionStore.selected === props.action.globalId
})


// 处理键盘导航
const handleKeyDown = (event: KeyboardEvent) => {
    switch (event.key) {
        case 'Enter':
        case ' ': // 空格键
            event.preventDefault()
            handleClick()
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
const handleClick = () => {
    logger.info('handleActionClicked 🍋', props.action.globalId);
    actionStore.selectAction(props.action.globalId)
}
</script>

<template>
    <ListItem bg-color="success" :selected="selected" :description="action.description + actionStore.selected!" :icon="action.icon" :tabindex="index + 1"
        @click="handleClick" @keydown="handleKeyDown" />
</template>
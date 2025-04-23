<script setup lang="ts">
import { SendableAction } from '@/types/sendable-action.js';
import ListItem from '@renderer/cosy/ListItem.vue'
import { logger } from '../utils/logger';
import { useActionStore } from '@renderer/stores/actionStore';
import { computed, ref } from 'vue';
import { onKeyStroke, useFocus } from '@vueuse/core';

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

// 创建引用来使用useFocus
const itemRef = ref<HTMLElement | null>(null)
const { focused } = useFocus(itemRef, { initialValue: false })

// 处理取消操作
const handleCancel = () => {
    emit('cancel')
}

const selected = computed(() => {
    return actionStore.selected === props.action.globalId
})

// 使用VueUse的onKeyStroke处理键盘事件
onKeyStroke(['Enter', ' '], (e) => {
    if (focused.value) {
        e.preventDefault()
        handleClick()
    }
}, { target: itemRef })

onKeyStroke('Escape', () => {
    if (focused.value) {
        handleCancel()
    }
})

onKeyStroke('ArrowUp', () => {
    if (focused.value) {
        emit('navigateUp')
    }
})

onKeyStroke('ArrowDown', () => {
    if (focused.value) {
        emit('navigateDown')
    }
})

// 处理动作选择
const handleClick = () => {
    logger.info('handleActionClicked 🍋', props.action.globalId);
    actionStore.setWillRun(props.action.globalId)
}
</script>

<template>
    <ListItem ref="itemRef" :selected="selected" :description="action.description" :icon="action.icon"
        :tabindex="index + 1" @click="handleClick" />
</template>
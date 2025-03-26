/**
* 插件动作项组件
*
* 功能：
* 1. 展示单个插件动作的信息
* 2. 处理动作的选择事件
* 3. 支持键盘导航
*/
<script setup lang="ts">
import type { SuperAction } from '@/types/super_action'
import { defineEmits } from 'vue'

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
    <li class="plugin-action-item p-3 border border-base-300 rounded-lg hover:bg-base-200 cursor-pointer transition-colors flex items-center"
        :tabindex="index + 1" @click="handleSelect" @keydown="handleKeyDown">
        <div v-if="action.icon" class="mr-3 text-xl">{{ action.icon }}</div>
        <div class="flex-1">
            <h3 class="font-medium">{{ action.title }}</h3>
            <p v-if="action.description" class="text-sm text-base-content/70">{{ action.description }}</p>
            <p class="text-xs text-base-content/50 mt-1">来自: {{ action.id }}</p>
        </div>
    </li>
</template>

<style scoped>
.plugin-action-item:focus {
    outline: 2px solid var(--primary);
    background-color: var(--primary-content/10);
}
</style>
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
    <li class="raycast-item" :tabindex="index + 1" @click="handleSelect" @keydown="handleKeyDown">
        <div v-if="action.icon" class="raycast-icon">{{ action.icon }}</div>
        <div class="raycast-content">
            <h3 class="raycast-title">{{ action.title }}</h3>
            <p v-if="action.description" class="raycast-description">{{ action.description }}</p>
            <p class="raycast-source">{{ action.id }}</p>
        </div>
    </li>
</template>

<style scoped>
.raycast-item {
    padding: 12px 14px;
    border-radius: 8px;
    cursor: pointer;
    display: flex;
    align-items: center;
    transition: all 0.2s ease;
    margin-bottom: 4px;
    background-color: var(--base-100);
}

.raycast-item:hover {
    background-color: var(--base-200);
    transform: translateY(-1px);
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.raycast-item:focus {
    outline: none;
    background-color: var(--primary-focus);
    box-shadow: 0 0 0 2px var(--primary);
}

.raycast-icon {
    margin-right: 12px;
    font-size: 18px;
    width: 28px;
    height: 28px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 6px;
    background-color: var(--primary);
    color: var(--primary-content);
}

.raycast-content {
    flex: 1;
}

.raycast-title {
    font-size: 14px;
    font-weight: 500;
    margin: 0;
    color: var(--base-content);
    line-height: 1.4;
}

.raycast-description {
    font-size: 12px;
    color: var(--base-content/70);
    margin: 2px 0 0 0;
    line-height: 1.4;
}

.raycast-source {
    font-size: 10px;
    color: var(--base-content/50);
    margin: 4px 0 0 0;
}
</style>
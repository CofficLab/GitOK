/**
* 窗口激活状态组件
*
* 此组件展示当前窗口的激活状态，并根据状态变化显示不同的样式
* 设计为在状态栏中使用，显示紧凑简洁
*/
<script setup lang="ts">
import { computed } from 'vue';
import { useAppStore } from '@renderer/stores/appStore';

const appStore = useAppStore();

// 计算属性：窗口激活状态
const isActive = computed(() => appStore.isActive);

// 计算属性：简短状态文本
const statusText = computed(() => isActive.value ? '已激活' : '未激活');

// 计算属性：状态点的样式类
const dotClass = computed(() => ({
    'bg-green-500': isActive.value,
    'bg-gray-400': !isActive.value,
}));

// 计算属性：文本颜色
const textClass = computed(() => ({
    'text-gray-800': isActive.value,
    'text-gray-500': !isActive.value,
}));
</script>

<template>
    <div class="window-active-status flex items-center">
        <div class="status-dot" :class="dotClass"></div>
        <span class="status-text" :class="textClass">{{ statusText }}</span>
    </div>
</template>

<style scoped>
.window-active-status {
    display: flex;
    align-items: center;
    gap: 4px;
    font-size: 0.75rem;
}

.status-dot {
    width: 6px;
    height: 6px;
    border-radius: 50%;
    transition: background-color 0.3s ease;
}

.status-text {
    transition: color 0.3s ease;
}
</style>
/**
* Card 组件 - Raycast UI 风格
*
* 功能：
* 1. 提供基于 Raycast 风格的卡片布局
* 2. 支持不同的变体（默认、紧凑、无边框）
* 3. 支持自定义内容布局
* 4. 支持可选的头部和底部区域
*/
<script setup lang="ts">
import { computed } from 'vue';

const props = defineProps<{
    // 卡片变体
    variant?: 'default' | 'compact' | 'borderless'
    // 是否可点击
    clickable?: boolean
    // 是否禁用
    disabled?: boolean
    // 按钮变体
    buttonVariant?: 'primary' | 'error' | 'info' | 'base'
    // 按钮状态
    loading?: boolean
}>()

// 默认值
const defaultProps = {
    variant: 'default',
    clickable: false,
    disabled: false,
    buttonVariant: 'base',
    loading: false
}

// 合并默认值
const finalProps = { ...defaultProps, ...props }

// 计算卡片类名
const cardClass = computed(() => {
    return [
        'raycast-card',
        `raycast-card--${finalProps.variant}`,
        {
            'raycast-card--clickable': finalProps.clickable,
            'raycast-card--disabled': finalProps.disabled
        }
    ]
})
</script>

<template>
    <div :class="cardClass">
        <div v-if="$slots.header" class="raycast-card__header">
            <slot name="header" />
        </div>
        <div class="raycast-card__content">
            <slot />
        </div>
        <div v-if="$slots.footer" class="raycast-card__footer">
            <slot name="footer">
                <button v-if="$slots.button" :class="[
                    'raycast-button',
                    `raycast-button--${finalProps.buttonVariant}`,
                    { 'raycast-button--loading': finalProps.loading }
                ]" :disabled="finalProps.disabled">
                    <slot name="button" />
                </button>
            </slot>
        </div>
    </div>
</template>

<style scoped>
.raycast-card {
    border-radius: 8px;
    background-color: var(--base-100);
    transition: all 0.2s ease;
}

/* 按钮基础样式 */
.raycast-button {
    display: inline-flex;
    align-items: center;
    padding: 0.25rem 0.75rem;
    font-size: 0.875rem;
    border-radius: 0.375rem;
    transition: all 0.2s ease;
    outline: none;
}

/* 按钮变体 */
.raycast-button--primary {
    background-color: var(--primary);
    color: var(--primary-content);
}

.raycast-button--primary:hover:not(:disabled) {
    background-color: var(--primary-focus);
}

.raycast-button--error {
    background-color: var(--error);
    color: var(--error-content);
}

.raycast-button--error:hover:not(:disabled) {
    background-color: var(--error-focus);
}

.raycast-button--info {
    background-color: var(--info);
    color: var(--info-content);
}

.raycast-button--info:hover:not(:disabled) {
    background-color: var(--info-focus);
}

.raycast-button--base {
    background-color: var(--base-300);
    color: var(--base-content);
}

.raycast-button--base:hover:not(:disabled) {
    background-color: var(--base-400);
}

/* 按钮状态 */
.raycast-button:disabled {
    opacity: 0.5;
    cursor: not-allowed;
}

.raycast-button--loading {
    cursor: wait;
    opacity: 0.7;
}

/* 默认变体 */
.raycast-card--default {
    padding: 16px;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

/* 紧凑变体 */
.raycast-card--compact {
    padding: 12px;
}

/* 无边框变体 */
.raycast-card--borderless {
    padding: 16px;
    background-color: transparent;
}

/* 可点击状态 */
.raycast-card--clickable {
    cursor: pointer;
}

.raycast-card--clickable:hover {
    background-color: var(--base-200);
    transform: translateY(-1px);
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.raycast-card--clickable:focus {
    outline: none;
    background-color: var(--primary-focus);
    box-shadow: 0 0 0 2px var(--primary);
}

/* 禁用状态 */
.raycast-card--disabled {
    opacity: 0.5;
    cursor: not-allowed;
}

/* 头部样式 */
.raycast-card__header {
    margin-bottom: 12px;
}

/* 内容区域样式 */
.raycast-card__content {
    color: var(--base-content);
}

/* 底部样式 */
.raycast-card__footer {
    margin-top: 12px;
    padding-top: 12px;
    border-top: 1px solid var(--base-200);
}
</style>
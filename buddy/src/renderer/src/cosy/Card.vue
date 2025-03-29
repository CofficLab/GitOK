/**
* Card 组件 - 基于 DaisyUI
*
* 功能：
* 1. 提供基于 DaisyUI 的卡片布局
* 2. 支持不同的变体和大小
* 3. 支持自定义内容布局
* 4. 支持可选的头部、内容和底部区域
* 5. 支持图片展示
*/
<script setup lang="ts">
import { computed } from 'vue';

interface Props {
    // 卡片样式
    bordered?: boolean
    // 卡片大小
    size?: 'xs' | 'sm' | 'md' | 'lg' | 'xl'
    // 是否为侧边布局（图片在侧边）
    side?: boolean
    // 是否为图片全屏模式
    imageFull?: boolean
    // 是否可点击
    clickable?: boolean
    // 是否禁用
    disabled?: boolean
    // 按钮变体
    buttonVariant?: 'primary' | 'secondary' | 'accent' | 'info' | 'success' | 'warning' | 'error' | 'ghost'
    // 按钮状态
    loading?: boolean
    // 图片地址
    image?: string
    // 图片描述
    imageAlt?: string
}

const props = withDefaults(defineProps<Props>(), {
    bordered: true,
    size: 'md',
    side: false,
    imageFull: false,
    clickable: false,
    disabled: false,
    buttonVariant: 'primary',
    loading: false
})

// 计算卡片类名
const cardClass = computed(() => {
    return [
        'card',
        {
            'card-bordered': props.bordered,
            'card-side': props.side,
            'image-full': props.imageFull,
            [`card-${props.size}`]: props.size !== 'md',
            'hover:shadow-lg transition-shadow cursor-pointer': props.clickable,
            'opacity-50 cursor-not-allowed': props.disabled
        }
    ]
})
</script>

<template>
    <div :class="cardClass">
        <!-- 卡片图片 -->
        <figure v-if="image || $slots.image">
            <slot name="image">
                <img v-if="image" :src="image" :alt="imageAlt || ''" />
            </slot>
        </figure>
        
        <!-- 卡片内容 -->
        <div class="card-body">
            <!-- 卡片标题 -->
            <slot name="title">
                <h2 v-if="$slots.header" class="card-title">
                    <slot name="header" />
                </h2>
            </slot>
            
            <!-- 卡片内容 -->
            <slot />
            
            <!-- 卡片操作区 -->
            <div v-if="$slots.footer || $slots.button" class="card-actions justify-end">
                <slot name="footer">
                    <button v-if="$slots.button" 
                        :class="['btn', `btn-${buttonVariant}`, { 'btn-disabled': disabled, 'loading': loading }]" 
                        :disabled="disabled">
                        <slot name="button" />
                    </button>
                </slot>
            </div>
        </div>
    </div>
</template>
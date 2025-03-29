<!--
Button 组件

一个基于 DaisyUI 的按钮组件，提供丰富的样式和功能选项。

使用示例：
```vue
<Button>默认按钮</Button>
<Button variant="primary">主要按钮</Button>
<Button variant="ghost" size="sm">小型幽灵按钮</Button>
<Button loading>加载中按钮</Button>
<Button disabled>禁用按钮</Button>
```

事件：
- click: 点击按钮时触发（disabled或loading状态下不触发）
-->

<script setup lang="ts">
import { computed } from 'vue';

interface Props {
  // 按钮颜色
  color?: 'neutral' | 'primary' | 'secondary' | 'accent' | 'info' | 'success' | 'warning' | 'error'
  // 按钮样式
  style?: 'outline' | 'dash' | 'soft' | 'ghost' | 'link'
  // 按钮大小
  size?: 'xs' | 'sm' | 'md' | 'lg' | 'xl'
  // 按钮形状
  shape?: 'wide' | 'block' | 'square' | 'circle'
  // 是否显示加载状态
  loading?: boolean
  // 是否禁用
  disabled?: boolean
  // 是否激活
  active?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  color: undefined,
  style: undefined,
  size: 'md',
  shape: undefined,
  loading: false,
  disabled: false,
  active: false
})

const emit = defineEmits<{
  (e: 'click', event: MouseEvent): void
}>()

const handleClick = (event: MouseEvent) => {
  if (!props.disabled && !props.loading) {
    emit('click', event)
  }
}

const classes = computed(() => {
  return [
    'btn',
    'no-drag-region',
    // 颜色类 - 显式列出所有可能的类名
    {
      'btn-neutral': props.color === 'neutral',
      'btn-primary': props.color === 'primary',
      'btn-secondary': props.color === 'secondary',
      'btn-accent': props.color === 'accent',
      'btn-info': props.color === 'info',
      'btn-success': props.color === 'success',
      'btn-warning': props.color === 'warning',
      'btn-error': props.color === 'error'
    },
    // 样式类 - 显式列出所有可能的类名
    {
      'btn-outline': props.style === 'outline',
      'btn-dash': props.style === 'dash',
      'btn-soft': props.style === 'soft',
      'btn-ghost': props.style === 'ghost',
      'btn-link': props.style === 'link'
    },
    // 大小类 - 显式列出所有可能的类名
    {
      'btn-xs': props.size === 'xs',
      'btn-sm': props.size === 'sm',
      'btn-md': props.size === 'md',
      'btn-lg': props.size === 'lg',
      'btn-xl': props.size === 'xl'
    },
    // 形状类 - 显式列出所有可能的类名
    {
      'btn-square': props.shape === 'square',
      'btn-circle': props.shape === 'circle'
    },
    // 状态类
    {
      'btn-active': props.active,
      'btn-disabled': props.disabled,
      'loading': props.loading
    }
  ]
})
</script>

<template>
  <button
    :class="classes"
    :disabled="disabled || loading"
    @click="handleClick"
  >
    <slot></slot>
  </button>
</template>
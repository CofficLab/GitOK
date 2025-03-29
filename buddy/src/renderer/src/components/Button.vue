<!--
Button 组件

一个基于DaisyUI和Tailwind的按钮组件，采用Raycast风格设计。

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
  variant?: 'default' | 'primary' | 'secondary' | 'accent' | 'ghost'
  size?: 'sm' | 'md' | 'lg'
  // 是否显示加载状态
  loading?: boolean
  disabled?: boolean
  // 是否为块级按钮（宽度100%）
  block?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  variant: 'default',
  size: 'md',
  loading: false,
  disabled: false,
  block: false
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
    'transition-all',
    'duration-200',
    'ease-in-out',
    'hover:brightness-110',
    'active:scale-95',
    {
      'btn-primary': props.variant === 'primary',
      'btn-secondary': props.variant === 'secondary',
      'btn-accent': props.variant === 'accent',
      'btn-ghost': props.variant === 'ghost',
      'btn-sm': props.size === 'sm',
      'btn-lg': props.size === 'lg',
      'w-full': props.block,
      'opacity-50 cursor-not-allowed': props.disabled,
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
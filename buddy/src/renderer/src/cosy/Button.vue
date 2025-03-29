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
    // 颜色类
    props.color ? `btn-${props.color}` : '',
    // 样式类
    props.style ? `btn-${props.style}` : '',
    // 大小类
    props.size !== 'md' ? `btn-${props.size}` : '',
    // 形状类
    props.shape ? `btn-${props.shape}` : '',
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
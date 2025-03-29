<!--
ToolBarItem 组件

一个用于在ToolBar中显示单个工具项的组件，支持可点击和不可点击两种状态。

使用示例：
```vue
<ToolBarItem>
  <i class="i-carbon-home"></i>
  <span>首页</span>
</ToolBarItem>

<ToolBarItem clickable @click="handleClick">
  <i class="i-carbon-refresh"></i>
  <span>刷新</span>
</ToolBarItem>

<ToolBarItem variant="primary">主要操作</ToolBarItem>
<ToolBarItem variant="success">成功状态</ToolBarItem>
<ToolBarItem variant="warning">警告状态</ToolBarItem>
<ToolBarItem variant="error">错误状态</ToolBarItem>
```

属性说明：
- clickable: 是否可点击
  - 类型: boolean
  - 默认值: false
- variant: 工具项变体
  - 可选值: 'default' | 'primary' | 'success' | 'warning' | 'error'
  - 默认值: 'default'
- active: 是否激活状态
  - 类型: boolean
  - 默认值: false

事件：
- click: 点击工具项时触发（仅在clickable为true时有效）
-->

<script setup lang="ts">
import { computed } from 'vue';

interface Props {
    // 是否可点击
    clickable?: boolean
    // 工具项变体
    variant?: 'default' | 'primary' | 'success' | 'warning' | 'error'
    // 是否激活状态
    active?: boolean
}

const props = withDefaults(defineProps<Props>(), {
    clickable: false,
    variant: 'default',
    active: false
})

const emit = defineEmits<{
    (e: 'click', event: MouseEvent): void
}>()

const handleClick = (event: MouseEvent) => {
    if (props.clickable) {
        emit('click', event)
    }
}

// 计算工具项类名
const itemClass = computed(() => {
    return [
        'tool-bar-item',
        'h-full',
        'flex',
        'items-center',
        'gap-1',
        'px-3',
        'text-sm',
        'transition-all',
        'duration-200',
        {
            'cursor-pointer hover:bg-base-300': props.clickable,
            'cursor-default': !props.clickable,
            'bg-base-300': props.active,
            'text-primary': props.variant === 'primary',
            'text-success': props.variant === 'success',
            'text-warning': props.variant === 'warning',
            'text-error': props.variant === 'error'
        }
    ]
})
</script>

<template>
    <div :class="itemClass" @click="handleClick">
        <slot></slot>
    </div>
</template>
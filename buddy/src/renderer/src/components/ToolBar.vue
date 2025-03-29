<!--
ToolBar 组件

一个基于DaisyUI的顶部工具栏组件，采用Raycast风格设计。
支持左中右三段式布局，可以放置按钮、URL输入框、图标和文字等元素。

使用示例：
```vue
<ToolBar>
  <template #left>
    <ToolBar.Item>
      <i class="i-carbon-menu"></i>
    </ToolBar.Item>
  </template>
  <template #center>
    <div class="w-full max-w-2xl">
      <input type="text" class="input input-sm w-full bg-base-300" placeholder="输入URL地址" />
    </div>
  </template>
  <template #right>
    <ToolBar.Item clickable @click="handleRefresh">
      <i class="i-carbon-refresh"></i>
    </ToolBar.Item>
  </template>
</ToolBar>
```

属性说明：
- variant: 工具栏变体
  - 可选值: 'default' | 'compact'
  - 默认值: 'default'
- bordered: 是否显示下边框
  - 类型: boolean
  - 默认值: true

插槽：
- left: 左侧内容区域
- center: 中间内容区域
- right: 右侧内容区域
-->

<script setup lang="ts">
import { computed } from 'vue';

interface Props {
    // 工具栏变体
    variant?: 'default' | 'compact'
    // 是否显示下边框
    bordered?: boolean
}

const props = withDefaults(defineProps<Props>(), {
    variant: 'default',
    bordered: true
})

// 计算工具栏类名
const toolBarClass = computed(() => {
    return [
        'w-full h-full',
        'flex',
        'justify-between',
        'items-center',
        'bg-base-200',
        'text-base-content/70',
        'text-sm',
        'no-drag-region',
        'transition-all',
        'duration-200',
        {
            'h-12': props.variant === 'default',
            'h-10': props.variant === 'compact',
            'border-b border-base-300': props.bordered
        }
    ]
})
</script>

<template>
    <div :class="toolBarClass">
        <!-- 左侧内容区域 -->
        <div class="flex items-center h-full overflow-hidden">
            <slot name="left"></slot>
        </div>

        <!-- 中间内容区域 -->
        <div class="flex-1 flex items-center justify-center h-full px-4 overflow-hidden">
            <slot name="center"></slot>
        </div>

        <!-- 右侧内容区域 -->
        <div class="flex items-center h-full overflow-hidden">
            <slot name="right"></slot>
        </div>
    </div>
</template>
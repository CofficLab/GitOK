<!--
StatusBar 组件

一个基于DaisyUI的底部状态栏组件，类似VSCode底部状态栏，采用Raycast风格设计。
支持左右两侧内容布局，可以放置按钮、图标和文字等元素。

使用示例：
```vue
<StatusBar>
  <template #left>
    <span>左侧状态信息</span>
  </template>
  <template #right>
    <span>右侧状态信息</span>
  </template>
</StatusBar>

<StatusBar>
  <template #left>
    <StatusBar.Item>
      <i class="i-carbon-information"></i>
      <span>分支: main</span>
    </StatusBar.Item>
    <StatusBar.Item>
      <i class="i-carbon-git-commit"></i>
      <span>3 changes</span>
    </StatusBar.Item>
  </template>
  <template #right>
    <StatusBar.Item clickable @click="handleClick">
      <i class="i-carbon-checkmark"></i>
      <span>Ready</span>
    </StatusBar.Item>
  </template>
</StatusBar>
```

属性说明：
- variant: 状态栏变体
  - 可选值: 'default' | 'compact'
  - 默认值: 'default'
- bordered: 是否显示上边框
  - 类型: boolean
  - 默认值: true

插槽：
- left: 左侧内容区域
- right: 右侧内容区域
-->

<script setup lang="ts">
import { computed } from 'vue';

interface Props {
  // 状态栏变体
  variant?: 'default' | 'compact'
  // 是否显示上边框
  bordered?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  variant: 'default',
  bordered: true
})

// 计算状态栏类名
const statusBarClass = computed(() => {
  return [
    'w-full h-full',
    'flex',
    'justify-between',
    'items-center',
    'bg-base-200',
    'text-base-content/70',
    'text-xs',
    'no-drag-region',
    'transition-all',
    'duration-200',
    {
      'h-8': props.variant === 'default',
      'h-6': props.variant === 'compact',
      'border-t border-base-300': props.bordered
    }
  ]
})
</script>

<template>
  <div :class="statusBarClass">
    <!-- 左侧内容区域 -->
    <div class="flex items-center h-full overflow-hidden">
      <slot name="left"></slot>
    </div>

    <!-- 右侧内容区域 -->
    <div class="flex items-center h-full overflow-hidden">
      <slot name="right"></slot>
    </div>
  </div>
</template>
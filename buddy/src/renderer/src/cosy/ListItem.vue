<!--
ListItem 组件

列表项组件，支持选择状态和交互动作。

使用示例：
```vue
<ListItem :selected="false" @click="handleClick">默认列表项</ListItem>
<ListItem :selected="true" icon="RiCheckLine">选中状态</ListItem>
<ListItem actionText="查看详情" @action="handleAction">带操作的列表项</ListItem>
```

事件：
- click: 点击列表项时触发
- action: 点击操作按钮时触发
-->

<script setup lang="ts">
import { RiCheckLine } from '@remixicon/vue'

interface Props {
  // 是否选中
  selected?: boolean
  // 图标
  icon?: string
  // 标题文本
  title?: string
  // 描述内容
  description?: string
  // 是否显示操作按钮
  actionable?: boolean
  // 自定义操作
  action?: () => void
  // 自定义操作文本
  actionText?: string
  // 是否显示边框
  border?: boolean
  // 背景色类名
  bgColor?: 'base' | 'primary' | 'secondary' | 'accent' | 'info' | 'success' | 'warning' | 'error'
}

const props = withDefaults(defineProps<Props>(), {
  selected: false,
  actionable: false,
  border: true,
  bgColor: 'base'
})

const emit = defineEmits<{
  (e: 'click'): void
  (e: 'action'): void
}>()

// 处理点击事件
const handleClick = () => {
  emit('click')
}

// 处理操作事件
const handleAction = () => {
  if (props.action) {
    props.action()
  }
  emit('action')
}
</script>

<template>
  <div 
    class="flex items-center p-3 cursor-pointer transition-colors duration-200 rounded-md"
    :class="{
      'bg-primary-focus': selected,
      'border-b border-base-200': border,
      'hover:bg-base-200': !selected && props.bgColor === 'base',
      'bg-base-100': !selected && props.bgColor === 'base',
      'hover:bg-primary': !selected && props.bgColor === 'primary',
      'bg-primary': !selected && props.bgColor === 'primary',
      'hover:bg-secondary': !selected && props.bgColor === 'secondary',
      'bg-secondary': !selected && props.bgColor === 'secondary',
      'hover:bg-accent': !selected && props.bgColor === 'accent',
      'bg-accent': !selected && props.bgColor === 'accent',
      'hover:bg-info': !selected && props.bgColor === 'info',
      'bg-info': !selected && props.bgColor === 'info',
      'hover:bg-success': !selected && props.bgColor === 'success',
      'bg-success': !selected && props.bgColor === 'success',
      'hover:bg-warning': !selected && props.bgColor === 'warning',
      'bg-warning': !selected && props.bgColor === 'warning',
      'hover:bg-error': !selected && props.bgColor === 'error',
      'bg-error': !selected && props.bgColor === 'error'
    }"
    @click="handleClick"
  >
    <RiCheckLine v-if="selected" class="mr-3 text-primary" />
    <div class="flex-1">
      <h3 v-if="title" class="font-medium mb-1 text-base-content">{{ title }}</h3>
      <p v-if="description" class="text-base-content/70 text-sm">{{ description }}</p>
    </div>
    <button 
      v-if="actionable" 
      class="px-2 py-1 rounded bg-primary text-primary-content border-none cursor-pointer" 
      @click.stop="handleAction"
    >
      {{ actionText || '操作' }}
    </button>
  </div>
</template>
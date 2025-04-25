<!--
Alert 组件

一个基于DaisyUI的警告提示组件，支持多种状态和关闭功能。采用Raycast风格设计。

使用示例：
```vue
<Alert>默认提示信息</Alert>
<Alert type="info" closable>可关闭的信息提示</Alert>
<Alert type="success">成功提示信息</Alert>
<Alert type="warning">警告提示信息</Alert>
<Alert type="error">错误提示信息</Alert>
<Alert message="通过属性传递的消息"></Alert>
```

事件：
- close: 点击关闭按钮时触发
-->

<script setup lang="ts">
import { RiInfoCardLine } from '@remixicon/vue'

interface Props {
  // 提示类型
  type?: 'info' | 'success' | 'warning' | 'error'
  // 是否可关闭
  closable?: boolean
  // 标题文本
  title?: string
  // 消息内容
  message?: string
  // 是否显示复制按钮
  copyable?: boolean
  // 自定义操作
  action?: () => void
  // 自定义操作文本
  actionText?: string
}

const props = withDefaults(defineProps<Props>(), {
  type: 'info',
  closable: false,
  copyable: true
})

// 复制到剪贴板
const copyToClipboard = () => {
  if (props.message) {
    navigator.clipboard.writeText(props.message)
      .catch(err => console.error('复制失败:', err))
  }
}
</script>

<template>
  <div role="alert" class="alert alert-vertical sm:alert-horizontal">
  <RiInfoCardLine />
  <span>{{ $props.message }}</span>
  <div>
    <button class="btn btn-sm" @click="action">{{ actionText }}</button>
    <button class="btn btn-sm btn-primary" v-if="copyable" @click="copyToClipboard">复制</button>
  </div>
</div>
</template>
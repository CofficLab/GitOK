<!--
Toast 组件

基于DaisyUI的轻量级消息提示组件，支持多种状态、位置和自动消失功能。

使用示例：
```vue
<Toast>默认提示消息</Toast>
<Toast type="success" duration="3000">操作成功</Toast>
<Toast type="error" position="bottom-center">发生错误</Toast>
<Toast type="warning" :duration="0">永久显示的警告</Toast>
```

属性说明：
- type: 提示类型
  - 可选值: 'default' | 'success' | 'error' | 'warning' | 'info'
  - 默认值: 'default'
- duration: 显示时长(毫秒)，设为0则不会自动关闭
  - 类型: number
  - 默认值: 2000
- position: 显示位置
  - 可选值: 'top-start' | 'top-center' | 'top-end' | 'bottom-start' | 'bottom-center' | 'bottom-end'
  - 默认值: 'top-center'

事件：
- close: Toast关闭时触发
-->

<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount, computed } from 'vue'

interface Props {
  type?: 'default' | 'success' | 'error' | 'warning' | 'info'
  duration?: number
  position?: 'top-start' | 'top-center' | 'top-end' | 'bottom-start' | 'bottom-center' | 'bottom-end'
}

const props = withDefaults(defineProps<Props>(), {
  type: 'default',
  duration: 2000,
  position: 'top-center'
})

const emit = defineEmits<{
  (e: 'close'): void
}>()

const visible = ref(true)
let timer: number | null = null

const handleClose = () => {
  visible.value = false
  emit('close')
}

onMounted(() => {
  if (props.duration > 0) {
    timer = window.setTimeout(() => {
      handleClose()
    }, props.duration)
  }
})

onBeforeUnmount(() => {
  if (timer) {
    clearTimeout(timer)
  }
})

const toastClass = computed(() => {
  return [
    'toast',
    'no-drag-region',
    'z-50',
    {
      'toast-top': props.position.startsWith('top'),
      'toast-bottom': props.position.startsWith('bottom'),
      'toast-start': props.position.endsWith('start'),
      'toast-center': props.position.endsWith('center'),
      'toast-end': props.position.endsWith('end')
    }
  ]
})

const alertClass = computed(() => {
  return [
    'alert',
    'shadow-lg',
    'min-w-[200px]',
    'max-w-[400px]',
    'animate-fade-in-down',
    {
      'alert-success': props.type === 'success',
      'alert-error': props.type === 'error',
      'alert-warning': props.type === 'warning',
      'alert-info': props.type === 'info'
    }
  ]
})

const iconClass = computed(() => {
  switch (props.type) {
    case 'success':
      return 'i-carbon-checkmark-filled'
    case 'error':
      return 'i-carbon-error-filled'
    case 'warning':
      return 'i-carbon-warning-filled'
    case 'info':
      return 'i-carbon-information-filled'
    default:
      return ''
  }
})
</script>

<template>
  <div v-if="visible" :class="toastClass">
    <div :class="alertClass">
      <div class="flex items-center gap-2">
        <span v-if="iconClass" :class="iconClass" class="w-5 h-5"></span>
        <span class="text-sm">
          <slot></slot>
        </span>
      </div>
    </div>
  </div>
</template>

<style scoped>
.animate-fade-in-down {
  animation: fade-in-down 0.3s ease-out;
}

@keyframes fade-in-down {
  from {
    opacity: 0;
    transform: translateY(-10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>
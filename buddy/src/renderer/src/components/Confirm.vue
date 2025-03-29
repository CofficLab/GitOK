<!--
Confirm 组件

一个基于DaisyUI的确认对话框组件，用于需要用户进一步确认的操作。采用Raycast风格设计。

使用示例：
```vue
<Confirm
  v-model="showConfirm"
  title="删除确认"
  message="确定要删除这个项目吗？"
  @confirm="handleDelete"
/>

<Confirm
  v-model="showConfirm"
  title="卸载插件"
  message="确定要卸载此插件吗？"
  confirm-text="确认卸载"
  cancel-text="取消"
  @confirm="handleUninstall"
  @cancel="hideConfirm"
/>
```

属性：
- modelValue: 控制对话框显示/隐藏
- title: 对话框标题
- message: 确认消息
- confirmText: 确认按钮文本，默认为"确认"
- cancelText: 取消按钮文本，默认为"取消"
- confirmVariant: 确认按钮样式，默认为"primary"
- cancelVariant: 取消按钮样式，默认为"ghost"
- loading: 确认按钮是否处于加载状态

事件：
- confirm: 点击确认按钮时触发
- cancel: 点击取消按钮时触发
- update:modelValue: 更新显示状态
-->

<script setup lang="ts">
import { ref, watch } from 'vue'
import Button from './Button.vue'

interface Props {
  // 控制对话框显示/隐藏
  modelValue: boolean
  // 对话框标题
  title?: string
  // 确认消息
  message?: string
  // 确认按钮文本
  confirmText?: string
  // 取消按钮文本
  cancelText?: string
  // 确认按钮样式
  confirmVariant?: 'default' | 'primary' | 'secondary' | 'accent' | 'ghost'
  // 取消按钮样式
  cancelVariant?: 'default' | 'primary' | 'secondary' | 'accent' | 'ghost'
  // 确认按钮是否处于加载状态
  loading?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  title: '',
  message: '',
  confirmText: '确认',
  cancelText: '取消',
  confirmVariant: 'primary',
  cancelVariant: 'ghost',
  loading: false
})

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void
  (e: 'confirm'): void
  (e: 'cancel'): void
}>()



// 处理确认
const handleConfirm = () => {
  emit('confirm')
}

// 对话框引用
const modalRef = ref<HTMLDialogElement | null>(null)

// 监听 modelValue 变化
watch(() => props.modelValue, (newVal) => {
  if (newVal && modalRef.value) {
    modalRef.value.showModal()
  } else if (modalRef.value) {
    modalRef.value.close()
  }
})

// 处理取消
const handleCancel = () => {
  emit('update:modelValue', false)
  emit('cancel')
}
</script>

<template>
  <dialog ref="modalRef" :open="modelValue" class="modal modal-middle">
    <div class="modal-box">
      <!-- 标题 -->
      <h3 v-if="title" class="font-bold text-lg mb-2">{{ title }}</h3>

      <!-- 消息 -->
      <div class="py-2">
        <slot>{{ message }}</slot>
      </div>

      <!-- 按钮组 -->
      <div class="modal-action">
        <Button :variant="cancelVariant" @click="handleCancel">
          {{ cancelText }}
        </Button>
        <Button :variant="confirmVariant" :loading="loading" @click="handleConfirm">
          {{ confirmText }}
        </Button>
      </div>
    </div>
    
    <!-- 遮罩层 -->
    <form method="dialog" class="modal-backdrop">
      <button @click="handleCancel">close</button>
    </form>
  </dialog>
</template>

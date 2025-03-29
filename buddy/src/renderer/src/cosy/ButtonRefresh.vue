<!--
ButtonRefresh 组件

一个专门用于刷新操作的按钮组件，封装了 Button 组件，并添加了动画效果。
当处于加载状态时，图标会旋转，提供视觉反馈。

使用示例：
```vue
<ButtonRefresh @click="refreshData" :loading="isLoading" />
<ButtonRefresh style="ghost" size="sm" @click="refreshData" />
```

属性：
- 继承 Button 组件的所有属性
- 默认使用 ghost 样式

事件：
- click: 点击按钮时触发（disabled或loading状态下不触发）
-->

<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import Button from './Button.vue'
import { RiRefreshLine } from '@remixicon/vue'

interface Props {
  // 按钮颜色
  color?: 'neutral' | 'primary' | 'secondary' | 'accent' | 'info' | 'success' | 'warning' | 'error'
  // 按钮样式
  style?: 'outline' | 'dash' | 'soft' | 'ghost' | 'link'
  // 按钮大小
  size?: 'xs' | 'sm' | 'md' | 'lg' | 'xl'
  // 按钮形状
  shape?: 'square' | 'circle'
  // 是否显示加载状态
  loading?: boolean
  // 是否禁用
  disabled?: boolean
  // 是否激活
  active?: boolean
  // 提示文本
  tooltip?: string
  // 最小动画时间（毫秒）
  minAnimationTime?: number
}

const props = withDefaults(defineProps<Props>(), {
  style: 'ghost',
  size: 'md',
  loading: false,
  disabled: false,
  active: false,
  minAnimationTime: 3000 // 默认最小动画时间为 3000 毫秒
})

const emit = defineEmits<{
  (e: 'click', event: MouseEvent): void
}>()

const handleClick = (event: MouseEvent) => {
  emit('click', event)
}

// 内部加载状态
const internalLoading = ref(false)

// 监听外部加载状态
watch(() => props.loading, (newVal, oldVal) => {
  if (newVal === true) {
    // 开始加载
    internalLoading.value = true
  } else if (oldVal === true && newVal === false) {
    // 加载结束，但要确保最小动画时间
    const animationStartTime = Date.now() - props.minAnimationTime
    const remainingTime = Math.max(0, props.minAnimationTime - (Date.now() - animationStartTime))
    
    if (remainingTime > 0) {
      setTimeout(() => {
        internalLoading.value = false
      }, remainingTime)
    } else {
      internalLoading.value = false
    }
  }
}, { immediate: true })

// 计算内容类名
const contentClass = computed(() => {
  return {
    'hidden': internalLoading.value
  }
})

// 计算加载器类名
const loadingClass = computed(() => {
  return [
    'loading',
    'loading-spinner',
    props.size === 'xs' || props.size === 'sm' ? 'loading-xs' : 
    props.size === 'lg' || props.size === 'xl' ? 'loading-lg' : 'loading-md',
    { 'hidden': !internalLoading.value }
  ]
})
</script>

<template>
  <div class="relative inline-block" :data-tip="tooltip" :class="{ 'tooltip': tooltip }">
    <Button
      :color="color"
      :style="style"
      :size="size"
      :shape="shape"
      :disabled="disabled || internalLoading"
      :active="active"
      @click="handleClick"
    >
      <span :class="loadingClass"></span>
      <span :class="contentClass">
        <RiRefreshLine class="transition-all duration-300" />
        <slot></slot>
      </span>
    </Button>
  </div>
</template>



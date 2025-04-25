<!--
Progress 组件

基于DaisyUI的进度条组件，支持多种颜色主题和进度值动态更新。
当不传入value时，将显示不确定进度的动画效果。

使用示例：
```vue
<Progress />
<Progress :value="40" />
<Progress :value="70" color="primary" />
<Progress :value="30" color="secondary" />
<Progress :value="50" color="accent" />
<Progress :value="60" color="info" />
<Progress :value="80" color="success" />
<Progress :value="90" color="warning" />
<Progress :value="20" color="error" />
```

属性说明：
- value: 当前进度值
- 类型: number
- 默认值: undefined (不传入时显示不确定进度动画)
- max: 最大值
- 类型: number
- 默认值: 100
- color: 颜色主题
- 可选值: 'neutral' | 'primary' | 'secondary' | 'accent' | 'info' | 'success' | 'warning' | 'error'
- 默认值: 'neutral'
-->

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
    // 当前进度值
    value?: number
    // 最大值
    max?: number
    // 颜色主题
    color?: 'neutral' | 'primary' | 'secondary' | 'accent' | 'info' | 'success' | 'warning' | 'error'
}

const props = withDefaults(defineProps<Props>(), {
    value: undefined,
    max: 100,
    color: 'neutral'
})

// 计算进度条的类名
const progressClass = computed(() => {
    const classes = ['progress', 'w-56']
    if (props.color !== 'neutral') {
        classes.push(`progress-${props.color}`)
    }
    return classes.join(' ')
})
</script>

<template>
    <progress :class="progressClass" :value="value" :max="max"></progress>
</template>
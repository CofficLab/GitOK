<!--
Badge 组件

一个基于DaisyUI的徽章组件，支持多种颜色变体、大小和样式。

使用示例：
```vue
<Badge>默认徽章</Badge>
<Badge variant="primary">主要徽章</Badge>
<Badge variant="secondary" size="lg">大号次要徽章</Badge>
<Badge variant="accent" outline>轮廓强调徽章</Badge>
<Badge variant="info" size="sm">小号信息徽章</Badge>
```

属性说明：
- variant: 徽章变体
  - 可选值: 'neutral' | 'primary' | 'secondary' | 'accent' | 'ghost' | 'info' | 'success' | 'warning' | 'error'
  - 默认值: 'neutral'
- size: 徽章大小
  - 可选值: 'sm' | 'md' | 'lg'
  - 默认值: 'md'
- outline: 是否显示轮廓样式
  - 类型: boolean
  - 默认值: false
-->

<script setup lang="ts">
import { computed } from 'vue'
interface Props {
    // 徽章变体
    variant?: 'neutral' | 'primary' | 'secondary' | 'accent' | 'ghost' | 'info' | 'success' | 'warning' | 'error'
    // 徽章大小
    size?: 'sm' | 'md' | 'lg'
    // 是否显示轮廓样式
    outline?: boolean
}

const props = withDefaults(defineProps<Props>(), {
    variant: 'neutral',
    size: 'md',
    outline: false
})

// 计算徽章的类名
const badgeClasses = computed(() => {
    const classes = ['badge']

    // 添加变体类名
    if (props.variant !== 'neutral') {
        classes.push(`badge-${props.variant}`)
    }

    // 添加大小类名
    if (props.size !== 'md') {
        classes.push(`badge-${props.size}`)
    }

    // 添加轮廓类名
    if (props.outline) {
        classes.push('badge-outline')
    }

    return classes.join(' ')
})
</script>

<template>
    <span :class="badgeClasses">
        <slot></slot>
    </span>
</template>
<!--
Empty 组件

一个基于DaisyUI的空状态提示组件，用于展示无数据、无记录等状态。采用Raycast风格设计。

使用示例：
```vue
<Empty>暂无数据</Empty>
<Empty message="暂无记录" />
<Empty icon="RiSearchLine">未找到搜索结果</Empty>
```

属性：
- message: 提示文本，可以通过属性或默认插槽传递
- icon: 自定义图标组件，默认使用 RiInformationLine
-->

<script setup lang="ts">
import { RiInformationLine } from '@remixicon/vue'

interface Props {
  // 提示文本
  message?: string
  // 自定义图标组件
  icon?: any
}

withDefaults(defineProps<Props>(), {
  icon: () => RiInformationLine
})
</script>

<template>
  <div class="col-span-full p-8 text-center">
    <div class="alert alert-info bg-opacity-20 shadow-sm">
      <component :is="icon" class="h-4 w-4 mr-2 stroke-current" />
      <span>
        <slot>{{ message }}</slot>
      </span>
    </div>
  </div>
</template>

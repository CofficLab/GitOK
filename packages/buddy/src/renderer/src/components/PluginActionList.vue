<!--
PluginActionList.vue - 插件动作列表组件

这个组件负责展示插件提供的动作列表，用于用户选择执行。

主要功能：
- 显示插件动作列表
- 处理动作选择事件
- 支持加载状态显示

props:
- actions: 要显示的动作列表
- loading: 是否正在加载动作

事件:
- select: 当用户选择一个动作时触发
-->

<script setup lang="ts">
import { defineProps, defineEmits } from 'vue'
import type { PluginAction } from './PluginManager.vue'

const props = defineProps<{
    actions: PluginAction[]
    loading: boolean
}>()

const emits = defineEmits<{
    select: [action: PluginAction]
}>()

// 执行动作
const executeAction = (action: PluginAction) => {
    emits('select', action)
}
</script>

<template>
    <div>
        <!-- 加载状态 -->
        <div v-if="loading" class="text-center py-4 text-gray-500">
            <p>加载中...</p>
        </div>

        <!-- 空状态 -->
        <div v-else-if="actions.length === 0" class="text-center py-8 text-gray-500">
            <p>没有找到匹配的动作</p>
            <p class="text-sm mt-2">尝试其他关键词或安装更多插件</p>
        </div>

        <!-- 动作列表 -->
        <ul v-else class="space-y-2">
            <li v-for="result in actions" :key="result.id" @click="executeAction(result)"
                class="p-3 border rounded-lg hover:bg-gray-50 cursor-pointer transition-colors flex items-center">
                <div v-if="result.icon" class="mr-3 text-xl">{{ result.icon }}</div>
                <div class="flex-1">
                    <h3 class="font-medium">{{ result.title }}</h3>
                    <p v-if="result.description" class="text-sm text-gray-600">{{ result.description }}</p>
                    <p class="text-xs text-gray-400 mt-1">来自: {{ result.plugin }}</p>
                </div>
            </li>
        </ul>
    </div>
</template>

<style scoped>
/* 可以在这里添加组件样式 */
</style>
<!--
 * SearchBar.vue - 搜索栏组件
 * 
 * 这个组件负责提供搜索功能的用户界面：
 * 1. 搜索输入框
 * 2. 搜索图标
 * 
 * 主要功能：
 * - 提供搜索输入界面
 * - 通过actionStore管理搜索状态
 * - 实时更新搜索关键词
 * - 自动获取焦点
 * 
 * 技术栈：
 * - Vue 3
 * - Pinia (actionStore)
 * - TailwindCSS
 * - DaisyUI
 * 
 * 注意事项：
 * - 搜索状态完全由actionStore管理
 * - 组件只负责UI交互，不直接处理搜索逻辑
 * - 使用v-model实现双向绑定
 -->

<script setup lang="ts">
import { ref, watch } from 'vue'
import { useActionStore } from '@renderer/stores/actionStore'
import { RiSearchLine } from '@remixicon/vue'

const actionStore = useActionStore()
const keyword = ref(actionStore.keyword)

// 监听本地关键词变化并更新 actionStore
watch(keyword, (newKeyword) => {
    console.log(`SearchBar: 关键词变化为 "${newKeyword}"`)
    // 使用updateKeyword触发搜索
    actionStore.updateKeyword(newKeyword)
})

// 处理键盘事件
const handleKeyDown = (event: KeyboardEvent) => {
    actionStore.handleKeyDown(event)
}

</script>

<template>
    <label class="input w-full">
        <RiSearchLine class="w-4 h-4" />
        <input type="search" v-model="keyword" @keydown="handleKeyDown" required placeholder="Search" />
    </label>
</template>
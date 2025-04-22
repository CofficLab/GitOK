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
import { ref, watch, onMounted, nextTick } from 'vue'
import { useActionStore } from '@renderer/stores/actionStore'
import { RiSearchLine } from '@remixicon/vue'

const actionStore = useActionStore()
const keyword = ref(actionStore.keyword)
const measureText = ref<HTMLElement | null>(null)
const inputWidth = ref(200)
const searchInput = ref<HTMLInputElement | null>(null)

// 监听本地关键词变化并更新 actionStore
watch(keyword, async (newKeyword) => {
    console.log(`SearchBar: 关键词变化为 "${newKeyword}"`)
    // 使用updateKeyword触发搜索
    actionStore.updateKeyword(newKeyword)

    // 等待DOM更新后计算宽度
    await nextTick()
    updateInputWidth()
})

// 处理键盘事件
const handleKeyDown = (event: KeyboardEvent) => {
    actionStore.handleKeyDown(event)
}

// 计算并更新输入框宽度
const updateInputWidth = () => {
    if (measureText.value) {
        // 获取隐藏文本的宽度，并添加一些额外空间
        const width = measureText.value.offsetWidth + 80
        // 设置最小宽度
        inputWidth.value = Math.max(200, width)
    }
}

// 组件挂载后初始化宽度和焦点
onMounted(() => {
    updateInputWidth()
    nextTick(() => {
        searchInput.value?.focus()
    })
})
</script>

<template>
    <div
        class="relative w-full h-full flex items-center drag-region ring-2 bg-amber-100/10 ring-blue-500/40 rounded-lg">
        <RiSearchLine class="w-10 h-8" />
        <div class="relative flex-grow h-full">
            <span class="invisible whitespace-pre" ref="measureText">{{ keyword || 'Search' }}</span>
            <input ref="searchInput" v-model="keyword" @keydown="handleKeyDown"
                class="absolute  text-2xl h-full top-0 left-0 w-full focus:outline-none focus:ring-0 focus:border-0 outline-0 border-0 ring-0 no-drag-region"
                :style="{ width: inputWidth + 'px' }" />
        </div>
    </div>
</template>
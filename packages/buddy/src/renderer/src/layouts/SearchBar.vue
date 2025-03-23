<!--
 * SearchBar.vue - 搜索栏组件
 * 
 * 这个组件负责提供搜索功能的用户界面：
 * 1. 搜索输入框
 * 2. 搜索图标
 * 
 * 主要功能：
 * - 提供搜索输入界面
 * - 通过searchStore管理搜索状态
 * - 实时更新搜索关键词
 * - 自动获取焦点
 * 
 * 技术栈：
 * - Vue 3
 * - Pinia (searchStore)
 * - TailwindCSS
 * 
 * 注意事项：
 * - 搜索状态完全由searchStore管理
 * - 组件只负责UI交互，不直接处理搜索逻辑
 * - 使用v-model实现双向绑定
 -->

<script setup lang="ts">
import { ref, watch, onMounted } from 'vue'
import { useSearchStore } from '../stores/searchStore'

const searchStore = useSearchStore()
// 使用本地ref来存储搜索关键词
const keyword = ref(searchStore.keyword)
// 搜索输入框引用
const searchInput = ref<HTMLInputElement | null>(null)

// 监听本地关键词变化并更新 searchStore
watch(keyword, (newKeyword) => {
    console.log(`SearchBar: 关键词变化为 "${newKeyword}"`)
    // 使用updateKeyword触发搜索
    searchStore.updateKeyword(newKeyword)
})

// 处理键盘事件
const handleKeyDown = (event: KeyboardEvent) => {
    searchStore.handleKeyDown(event)
}

// 组件挂载后自动聚焦搜索框
onMounted(() => {
    focusSearch()
})

// 聚焦搜索框的方法(可以从外部调用)
const focusSearch = () => {
    if (searchInput.value) {
        searchInput.value.focus()
        console.log('尝试聚焦搜索框')
    } else {
        console.warn('搜索框元素未找到')
    }
}

// 暴露方法给父组件
defineExpose({
    focus: focusSearch
})
</script>

<template>
    <div class="flex items-center px-4 py-2 bg-gray-100 z-10">
        <div class="relative flex-1" @click="focusSearch">
            <span class="absolute inset-y-0 left-0 flex items-center pl-2 pointer-events-none">
                <svg class="w-4 h-4 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                        d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
            </span>
            <input ref="searchInput" v-model="keyword" type="text" autocomplete="off" placeholder="Search actions..."
                @keydown="handleKeyDown"
                class="w-full pl-10 pr-4 py-2 border rounded-lg focus:outline-none focus:border-blue-500 bg-white" />
        </div>
    </div>
</template>
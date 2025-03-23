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
import { useSearchStore } from '../stores/searchStore'
import { storeToRefs } from 'pinia'

const searchStore = useSearchStore()
const { keyword } = storeToRefs(searchStore)
</script>

<template>
    <div class="flex items-center px-4 py-2 bg-gray-100">
        <div class="relative flex-1">
            <span class="absolute inset-y-0 left-0 flex items-center pl-2">
                <svg class="w-4 h-4 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                        d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
            </span>
            <input v-model="keyword" type="text" placeholder="Search actions..."
                class="w-full pl-10 pr-4 py-2 border rounded-lg focus:outline-none focus:border-blue-500" />
        </div>
    </div>
</template>
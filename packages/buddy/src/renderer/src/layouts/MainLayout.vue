<!--
MainLayout.vue - 主布局组件

这是应用的主布局组件，负责：
1. 定义应用的基本布局结构
2. 管理标题栏、内容区和状态栏的位置关系
3. 提供具名插槽用于内容注入：
   - search: 搜索区域
   - content: 主要内容区域

布局结构：
┌─────────────────┐
│    TitleBar     │
├─────────────────┤
│    SearchBar    │
│  ┌───────────┐  │
│  │  Content  │  │
│  │           │  │
│  └───────────┘  │
├─────────────────┤
│   StatusBar     │
└─────────────────┘

技术栈：
- Vue 3 组合式API
- TailwindCSS 样式

注意事项：
- 这是一个无状态组件，只负责布局
- 使用具名插槽来组织内容
- 背景支持毛玻璃效果
-->

<script setup lang="ts">
import TitleBar from '@renderer/layouts/TitleBar.vue'
import StatusBar from '@renderer/layouts/StatusBar.vue'

// 布局组件不需要维护任何状态，只负责布局结构
</script>

<template>
    <div class="relative h-screen flex flex-col bg-transparent w-full">
        <!-- 标题栏 -->
        <TitleBar />

        <!-- 主内容区 -->
        <div class="flex-1 flex flex-col justify-center items-center">
            <div
                class="flex-1 flex flex-col overflow-hidden max-w-3xl mx-auto w-full bg-[rgba(30,30,30,0.8)] rounded-xl shadow-lg shadow-black/30 backdrop-blur-xl p-3">
                <!-- 搜索区域插槽 -->
                <div class="mb-4">
                    <slot name="search"></slot>
                </div>

                <!-- 内容区域插槽 -->
                <div class="flex-1 overflow-hidden">
                    <slot name="content"></slot>
                </div>
            </div>
        </div>

        <!-- 状态栏 -->
        <StatusBar />
    </div>
</template>
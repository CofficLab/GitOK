/**
* MainLayout.vue - 主布局组件
*
* 这是应用的主布局组件，负责：
* 1. 定义应用的基本布局结构
* 2. 管理标题栏、内容区和状态栏的位置关系
* 3. 通过命名插槽接收内容
*/

<script setup lang="ts">
import TitleBar from './TitleBar.vue'
import StatusBar from './StatusBar.vue'
// 移除 SearchBar 导入，将从 App.vue 通过插槽传入
</script>

<template>
    <div class="layout">
        <div class="flex flex-col h-screen">
            <!-- 标题栏 -->
            <TitleBar />

            <!-- 搜索框 - 使用命名插槽 -->
            <slot name="search"></slot>

            <!-- 内容区域 - 使用命名插槽 -->
            <div class="flex flex-1 overflow-hidden">
                <slot name="content"></slot>
            </div>

            <!-- 状态栏 -->
            <StatusBar />
        </div>
    </div>
</template>
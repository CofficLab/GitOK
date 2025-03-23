/**
* MainLayout.vue - 主布局组件
*
* 这是应用的主布局组件，负责：
* 1. 定义应用的基本布局结构
* 2. 管理标题栏、内容区和状态栏的位置关系
* 3. 使用 router-view 来显示动态内容
*/

<script setup lang="ts">
import TitleBar from './TitleBar.vue'
import StatusBar from './StatusBar.vue'
import SearchBar from './SearchBar.vue'
</script>

<template>
    <div class="layout">
        <div class="flex flex-col h-screen">
            <!-- 标题栏 -->
            <TitleBar />

            <!-- 搜索框 -->
            <SearchBar />

            <!-- 内容区域：使用路由视图 -->
            <div class="flex flex-1 overflow-hidden">
                <router-view v-slot="{ Component }">
                    <component :is="Component" />
                </router-view>
            </div>

            <!-- 状态栏 -->
            <StatusBar />
        </div>
    </div>
</template>
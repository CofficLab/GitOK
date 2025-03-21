<script setup lang="ts">
import { ref, reactive } from 'vue'
import TitleBar from './components/TitleBar.vue'
import SearchBar from './components/SearchBar.vue'
import PluginActionList from './components/PluginActionList.vue'
import StatusBar from './components/StatusBar.vue'
import PluginManager from './components/PluginManager.vue'
import type { PluginAction } from './components/PluginManager.vue'

// 搜索关键词
const searchKeyword = ref('')

// PluginManager组件引用
const pluginManager = ref()

// 状态信息
const statusInfo = reactive({
    gitRepo: "GitOK",
    branch: "main",
    commits: 128,
    lastUpdated: "10分钟前"
})

// 搜索处理
const handleSearch = (keyword: string) => {
    console.log(`搜索: ${keyword}`)
    // 点击搜索按钮时可以执行特定逻辑
}

// 处理实时输入
const handleInput = (keyword: string) => {
    searchKeyword.value = keyword
    console.log(`触发插件管理系统, 关键字: ${keyword}`)
    // 此处可以调用真实的插件管理系统API
}

// 插件动作执行
const executePluginAction = async (action: PluginAction) => {
    console.log(`执行插件动作: ${action.title}，来自插件: ${action.plugin}`)
    try {
        await pluginManager.value.executePluginAction(action.id)
    } catch (error) {
        console.error(`执行插件动作失败: ${error}`)
    }
}

// 按下Enter键触发搜索
const handleKeyDown = (event: KeyboardEvent) => {
    if (event.key === 'ArrowDown') {
        // 焦点移到第一个结果（可以进一步实现完整的键盘导航）
        const firstResult = document.querySelector('.results-container li a') as HTMLElement
        firstResult?.focus()
    }
}
</script>

<template>
    <div class="app-container h-screen flex flex-col justify-center items-center bg-base-100 text-base-content w-full">
        <TitleBar />

        <!-- 插件管理器 -->
        <PluginManager ref="pluginManager" />

        <div class="main-container flex-1 flex flex-col overflow-hidden p-4 max-w-3xl mx-auto">
            <!-- 搜索框组件 -->
            <SearchBar placeholder="搜索Git命令、NPM操作或VS Code功能..." @search="handleSearch" @input="handleInput"
                @keydown="handleKeyDown" />

            <!-- 插件动作列表组件 -->
            <PluginActionList :actions="pluginManager?.pluginActions || []" :searchKeyword="searchKeyword"
                @execute="executePluginAction" />

            <!-- 状态栏组件 -->
            <StatusBar :gitRepo="statusInfo.gitRepo" :branch="statusInfo.branch" :commits="statusInfo.commits"
                :lastUpdated="statusInfo.lastUpdated" />
        </div>
    </div>
</template>

<style scoped>
.main-container {
    max-height: calc(100vh - 32px);
    /* 减去TitleBar的高度 */
}
</style>
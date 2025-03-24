<!--
App.vue - 应用程序入口组件

这是应用的根组件，主要负责：
1. 组织整体布局结构（使用MainLayout组件）
2. 管理插件系统的生命周期
3. 处理插件消息通信
4. 管理全局快捷键

技术栈：
- Vue 3 组合式API
- Pinia 状态管理
- Electron IPC通信

注意事项：
- 所有的状态管理都通过pinia store处理
- 插件通信使用electron的IPC机制
- 组件间通过store而不是props通信
-->

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import SearchBar from './layouts/SearchBar.vue'
import MainLayout from './layouts/MainLayout.vue'
import ContentView from './layouts/ContentView.vue'
import { useActionStore } from './stores/actionStore'

const searchBar = ref()
const actionStore = useActionStore()

// 处理全局键盘事件
const handleGlobalKeyDown = (event: KeyboardEvent) => {
    // 如果用户按下斜杠(/)键，聚焦搜索框
    if (event.key === '/' && !isInputElement(event.target as HTMLElement)) {
        event.preventDefault()
        focusSearchBar()
    }

    // 如果用户按下Ctrl+K或Cmd+K，聚焦搜索框
    if ((event.ctrlKey || event.metaKey) && event.key === 'k') {
        event.preventDefault()
        focusSearchBar()
    }
}

// 检查元素是否为输入元素
const isInputElement = (element: HTMLElement | null): boolean => {
    if (!element) return false

    const tagName = element.tagName.toLowerCase()
    return tagName === 'input' ||
        tagName === 'textarea' ||
        element.isContentEditable
}

// 聚焦搜索框
const focusSearchBar = () => {
    if (searchBar.value?.focus) {
        searchBar.value.focus()
    }
}

// 在组件加载时注册消息监听和初始化
onMounted(() => {
    // 注册全局键盘事件
    document.addEventListener('keydown', handleGlobalKeyDown)

    // 初始加载插件动作
    actionStore.loadList()

    // 初始聚焦搜索框
    setTimeout(focusSearchBar, 300)
})

// 在组件卸载时清理消息监听
onUnmounted(() => {
    // 移除全局键盘事件
    document.removeEventListener('keydown', handleGlobalKeyDown)
})

</script>

<template>
    <MainLayout>
        <!-- 搜索区域 -->
        <template #search>
            <SearchBar ref="searchBar" class="search-container" />
        </template>

        <!-- 内容区域 -->
        <template #content>
            <ContentView />
        </template>
    </MainLayout>
</template>
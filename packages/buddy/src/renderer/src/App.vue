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
import { ref, reactive, onMounted, onUnmounted } from 'vue'
import SearchBar from './layouts/SearchBar.vue'
import PluginManager from './components/PluginManager.vue'
import { useSearchStore } from './stores/searchStore'
import MainLayout from './layouts/MainLayout.vue'
import ContentView from './layouts/ContentView.vue'

// PluginManager组件引用
const pluginManager = ref()
// SearchBar组件引用
const searchBar = ref()

// 使用搜索store
const searchStore = useSearchStore()

// 应用状态
const appState = reactive({
    showPluginStore: false
})

// 处理从插件视图接收的消息
const handlePluginMessage = (...args: unknown[]) => {
    const message = args[1] as { viewId: string, channel: string, data: any };

    console.log(`收到插件消息 - 视图ID: ${message.viewId}, 频道: ${message.channel}`, message.data)

    // 根据消息类型处理不同的操作
    switch (message.channel) {
        case 'close':
            searchStore.clearSelectedAction()
            break
        case 'execute-action':
            if (message.data?.actionId && pluginManager.value) {
                pluginManager.value.executeAction(message.data.actionId)
            }
            break
        // 可以根据需要添加更多消息类型处理
    }
}

// 处理插件视图请求关闭
const handlePluginCloseRequest = (...args: unknown[]) => {
    const message = args[1] as { viewId: string };

    console.log(`插件视图请求关闭: ${message.viewId}`)
    searchStore.clearSelectedAction()
}

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
    // 注册接收插件消息的处理函数
    window.electron.receive('plugin-message', handlePluginMessage)
    // 注册插件视图请求关闭的处理函数
    window.electron.receive('plugin-close-requested', handlePluginCloseRequest)

    // 注册全局键盘事件
    document.addEventListener('keydown', handleGlobalKeyDown)

    // 初始加载插件动作
    searchStore.loadPluginActions()

    // 初始聚焦搜索框
    setTimeout(focusSearchBar, 300)
})

// 在组件卸载时清理消息监听
onUnmounted(() => {
    // 移除消息监听
    window.electron.removeListener('plugin-message', handlePluginMessage)
    window.electron.removeListener('plugin-close-requested', handlePluginCloseRequest)

    // 移除全局键盘事件
    document.removeEventListener('keydown', handleGlobalKeyDown)
})
</script>

<template>
    <MainLayout>
        <!-- 插件管理器 -->
        <PluginManager ref="pluginManager" />

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
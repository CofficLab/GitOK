<!--
App.vue - 应用程序入口组件

这是应用的根组件，主要负责：
1. 组织整体布局结构（使用MainLayout组件）
2. 管理插件系统的生命周期
3. 处理插件消息通信
4. 协调搜索功能和插件动作的关联

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
import { ref, reactive, onMounted, onUnmounted, watch } from 'vue'
import SearchBar from './layouts/SearchBar.vue'
import PluginManager from './components/PluginManager.vue'
import type { PluginAction } from './components/PluginManager.vue'
import { useSearchStore } from './stores/searchStore'
import MainLayout from './layouts/MainLayout.vue'
import ContentView from './layouts/ContentView.vue'

// PluginManager组件引用
const pluginManager = ref()

// 使用搜索store
const searchStore = useSearchStore()

// 应用状态
const appState = reactive({
    showPluginStore: false,
    selectedAction: null as PluginAction | null
})

// 处理从插件视图接收的消息
const handlePluginMessage = (...args: unknown[]) => {
    const message = args[1] as { viewId: string, channel: string, data: any };

    console.log(`收到插件消息 - 视图ID: ${message.viewId}, 频道: ${message.channel}`, message.data)

    // 根据消息类型处理不同的操作
    switch (message.channel) {
        case 'close':
            appState.selectedAction = null
            break
        case 'execute-action':
            if (message.data?.actionId && pluginManager.value) {
                pluginManager.value.executePluginAction(message.data.actionId)
            }
            break
        // 可以根据需要添加更多消息类型处理
    }
}

// 处理插件视图请求关闭
const handlePluginCloseRequest = (...args: unknown[]) => {
    const message = args[1] as { viewId: string };

    console.log(`插件视图请求关闭: ${message.viewId}`)
    appState.selectedAction = null
}

// 在组件加载时注册消息监听
onMounted(() => {
    // 注册接收插件消息的处理函数
    window.electron.receive('plugin-message', handlePluginMessage)
    // 注册插件视图请求关闭的处理函数
    window.electron.receive('plugin-close-requested', handlePluginCloseRequest)

    // 监听搜索关键词变化
    watch(() => searchStore.keyword, async (newKeyword) => {
        if (pluginManager.value) {
            const actions = await pluginManager.value.loadPluginActions(newKeyword)
            searchStore.updatePluginActions(actions)
        }
    })
})

// 在组件卸载时清理消息监听
onUnmounted(() => {
    // 移除消息监听
    window.electron.removeListener('plugin-message', handlePluginMessage)
    window.electron.removeListener('plugin-close-requested', handlePluginCloseRequest)
})
</script>

<template>
    <MainLayout>
        <!-- 插件管理器 -->
        <PluginManager ref="pluginManager" />

        <!-- 搜索区域 -->
        <template #search>
            <SearchBar class="search-container" />
        </template>

        <!-- 内容区域 -->
        <template #content>
            <ContentView />
        </template>
    </MainLayout>
</template>
<!--
App.vue - 应用程序入口组件

这是应用的根组件，主要负责：
1. 组织整体布局结构
2. 管理插件系统的生命周期
3. 处理插件消息通信
4. 管理全局快捷键
5. 管理窗口激活状态监听

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
import { onMounted, onUnmounted } from 'vue'
import SearchBar from './layouts/SearchBar.vue'
import ContentView from './layouts/ContentView.vue'
import StatusBar from './layouts/StatusBar.vue'
import Confirm from './components/Confirm.vue'
import { useActionStore } from './stores/actionStore'
import { globalConfirm } from './composables/useConfirm'

const actionStore = useActionStore()

// 在组件加载时注册消息监听和初始化
onMounted(() => {
    // 初始加载插件动作
    actionStore.loadList()

    // 设置窗口激活状态监听，当窗口激活时刷新动作列表
    actionStore.setupWindowActivationListener()
})

// 在组件卸载时清理消息监听
onUnmounted(() => {
    // 清理窗口激活状态监听
    actionStore.cleanupWindowActivationListener()
})
</script>

<template>
    <div class="flex flex-col h-screen frosted-glass">
        <!-- 搜索区域 - 这里是可拖动区域 -->
        <div class="h-10 mt-4 px-4">
            <SearchBar />
        </div>

        <!-- 内容区域 -->
        <div class="flex flex-grow overflow-hidden no-drag-region">
            <ContentView />
        </div>

        <!-- 状态栏 -->
        <div class="h-10 border-t border-base-200 dark:border-base-300 no-drag-region">
            <StatusBar />
        </div>
    </div>

    <!-- 全局确认对话框 -->
    <Confirm
        v-model="globalConfirm.state.value.show"
        :title="globalConfirm.state.value.title"
        :message="globalConfirm.state.value.message"
        :confirm-text="globalConfirm.state.value.confirmText"
        :cancel-text="globalConfirm.state.value.cancelText"
        :confirm-variant="globalConfirm.state.value.confirmVariant"
        :cancel-variant="globalConfirm.state.value.cancelVariant"
        :loading="globalConfirm.state.value.loading"
        @confirm="globalConfirm.handleConfirm"
        @cancel="globalConfirm.handleCancel"
    />
</template>
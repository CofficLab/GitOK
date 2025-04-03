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
import StatusBar from './layouts/StatusBar.vue'
import Confirm from './cosy/Confirm.vue'
import Toast from './cosy/Toast.vue'
import Alert from './cosy/Alert.vue'
import Progress from './cosy/Progress.vue'
import { useActionStore } from './stores/actionStore'
import { useMarketStore } from './stores/marketStore'
import { globalConfirm } from './composables/useConfirm'
import { globalToast } from './composables/useToast'
import { globalAlert } from './composables/useAlert'
import { globalProgress } from './composables/useProgress'

const actionStore = useActionStore()
const marketStore = useMarketStore()

// 在组件加载时注册消息监听和初始化
onMounted(() => {
    // 初始加载插件动作
    actionStore.loadList()

    // 设置窗口激活状态监听，当窗口激活时刷新动作列表
    actionStore.setupWindowActivationListener()

    marketStore.updateUserPluginDirectory()
    marketStore.loadUserPlugins()
    marketStore.loadDevPlugins()
    marketStore.loadRemotePlugins()
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

        <!-- 全局进度条 -->
        <div class="absolute top-14 left-1/2 transform -translate-x-1/2">
            <Progress v-if="globalProgress.state.value.show" :value="globalProgress.state.value.value"
                :max="globalProgress.state.value.max" :color="globalProgress.state.value.color" />
        </div>

        <!-- 全局警告提示 -->
        <Alert v-if="globalAlert.state.value.show" :type="globalAlert.state.value.type"
            :message="globalAlert.state.value.message" :closable="globalAlert.state.value.closable"
            @close="globalAlert.close" />

        <!-- 内容区域 -->
        <div class="flex-1 overflow-hidden no-drag-region">
            <router-view v-slot="{ Component }">
                <transition name="fade" mode="out-in">
                    <component :is="Component" class="h-full w-full" />
                </transition>
            </router-view>
        </div>

        <!-- 状态栏 -->
        <div class="h-10 border-t border-base-200 dark:border-base-300 no-drag-region">
            <StatusBar />
        </div>
    </div>

    <!-- 全局确认对话框 -->
    <Confirm v-model="globalConfirm.state.value.show" :title="globalConfirm.state.value.title"
        :message="globalConfirm.state.value.message" :confirm-text="globalConfirm.state.value.confirmText"
        :cancel-text="globalConfirm.state.value.cancelText" :confirm-variant="globalConfirm.state.value.confirmVariant"
        :cancel-variant="globalConfirm.state.value.cancelVariant" :loading="globalConfirm.state.value.loading"
        @confirm="globalConfirm.handleConfirm" @cancel="globalConfirm.handleCancel" />

    <!-- 全局消息提示 -->
    <Toast v-if="globalToast.state.value.show" :type="globalToast.state.value.type"
        :duration="globalToast.state.value.duration" :position="globalToast.state.value.position"
        @close="globalToast.close">
        {{ globalToast.state.value.message }}
    </Toast>
</template>

<style>
.fade-enter-active,
.fade-leave-active {
    transition: opacity 0.15s ease;
}

.fade-enter-from,
.fade-leave-to {
    opacity: 0;
}
</style>
<script setup lang="ts">
import { ref, reactive, computed, onMounted, onUnmounted, watch } from 'vue'
import TitleBar from './components/TitleBar.vue'
import SearchBar from './components/SearchBar.vue'
import PluginActionList from './components/PluginActionList.vue'
import StatusBar from './components/StatusBar.vue'
import PluginManager from './components/PluginManager.vue'
import PluginStore from './components/PluginStore.vue'
import ActionView from './components/ActionView.vue'
import type { PluginAction } from './components/PluginManager.vue'
import { useSearchStore } from './stores/searchStore'

// PluginManager组件引用
const pluginManager = ref()
const actionView = ref()

// 使用搜索store
const searchStore = useSearchStore()

// 应用状态
const appState = reactive({
    showPluginStore: false,
    selectedAction: null as PluginAction | null
})

// 插件动作执行
const executePluginAction = async (action: PluginAction) => {
    console.log(`执行插件动作: ${action.title}，来自插件: ${action.plugin}`)

    // 设置当前选中的动作
    appState.selectedAction = action

    try {
        // 如果动作有视图，显示视图，否则执行动作
        if (action.viewPath) {
            console.log(`动作有自定义视图: ${action.viewPath}`)
        } else {
            await pluginManager.value.executePluginAction(action.id)
        }
    } catch (error) {
        console.error(`执行插件动作失败: ${error}`)
    }
}

// 处理从插件视图接收的消息
const handlePluginMessage = (...args: unknown[]) => {
    const message = args[1] as { viewId: string, channel: string, data: any };

    console.log(`收到插件消息 - 视图ID: ${message.viewId}, 频道: ${message.channel}`, message.data)

    // 根据消息类型处理不同的操作
    switch (message.channel) {
        case 'close':
            closePluginView()
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
    closePluginView()
}

// 关闭当前插件视图
const closePluginView = () => {
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

// 计算属性：是否显示主界面
const showMainInterface = computed(() => !appState.showPluginStore || !!appState.selectedAction)
// 计算属性：是否显示插件商店
const showPluginStore = computed(() => appState.showPluginStore && !appState.selectedAction)
// 计算属性：是否显示动作视图
const showActionView = computed(() => !!appState.selectedAction)
</script>

<template>
    <div class="relative h-screen flex flex-col justify-center items-center bg-transparent w-full">
        <TitleBar />

        <!-- 插件管理器 -->
        <PluginManager ref="pluginManager" />

        <!-- 主容器 -->
        <div
            class="flex-1 flex flex-col overflow-hidden max-w-3xl mx-auto w-full bg-[rgba(30,30,30,0.8)] rounded-xl shadow-lg shadow-black/30 backdrop-blur-xl p-3">
            <!-- 主界面 -->
            <div v-if="showMainInterface" class="flex-1 flex flex-col">
                <!-- 搜索框组件 -->
                <SearchBar class="search-container" />

                <!-- 动作视图（如果有选中的动作） -->
                <div v-if="showActionView" class="flex-1 mt-4 overflow-hidden">
                    <ActionView ref="actionView" :action="appState.selectedAction" />
                    <!-- 添加返回按钮 -->
                    <div class="mt-2 flex justify-end">
                        <button @click="closePluginView" class="btn btn-sm btn-ghost">
                            <i class="i-mdi-arrow-left mr-1"></i>
                            返回
                        </button>
                    </div>
                </div>
                <!-- 否则显示动作列表 -->
                <div v-else class="flex-1">
                    <PluginActionList :actions="searchStore.pluginActions" :searchKeyword="searchStore.keyword"
                        @execute="executePluginAction" class="text-white" />
                </div>
            </div>

            <!-- 插件商店 -->
            <div v-if="showPluginStore" class="flex-1 overflow-hidden">
                <PluginStore />
            </div>
        </div>

        <!-- 状态栏 -->
        <StatusBar></StatusBar>
    </div>
</template>
<script setup lang="ts">
import { ref, reactive, computed, onMounted, onUnmounted } from 'vue'
import TitleBar from './components/TitleBar.vue'
import SearchBar from './components/SearchBar.vue'
import PluginActionList from './components/PluginActionList.vue'
import StatusBar from './components/StatusBar.vue'
import PluginManager from './components/PluginManager.vue'
import PluginStore from './components/PluginStore.vue'
import ActionView from './components/ActionView.vue'
import type { PluginAction } from './components/PluginManager.vue'

// 检查是否为Spotlight模式
const isSpotlightMode = ref(false)

// 获取窗口配置
onMounted(async () => {
    try {
        const config = await window.electron.getWindowConfig()
        isSpotlightMode.value = config.spotlightMode || false
    } catch (error) {
        console.error('获取窗口配置失败:', error)
    }
})

// 搜索关键词
const searchKeyword = ref('')

// PluginManager组件引用
const pluginManager = ref()
const actionView = ref()

// 状态信息
const statusInfo = reactive({
    gitRepo: "GitOK",
    branch: "main",
    commits: 128,
    lastUpdated: "10分钟前"
})

// 应用状态
const appState = reactive({
    showPluginStore: false,
    selectedAction: null as PluginAction | null
})

// 显示插件商店
const togglePluginStore = () => {
    appState.showPluginStore = !appState.showPluginStore
    // 如果关闭插件商店，回到主界面
    if (!appState.showPluginStore) {
        appState.selectedAction = null
    }
}

// 搜索处理
const handleSearch = (keyword: string) => {
    console.log(`搜索: ${keyword}`)
    // 点击搜索按钮时可以执行特定逻辑
}

// 处理实时输入
const handleInput = async (keyword: string) => {
    searchKeyword.value = keyword
    console.log(`触发插件管理系统, 关键字: ${keyword}`)

    // 使用新的关键字获取动作
    if (pluginManager.value) {
        await pluginManager.value.loadPluginActions(keyword)
    }
}

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

// 按下Enter键触发搜索
const handleKeyDown = (event: KeyboardEvent) => {
    if (event.key === 'ArrowDown') {
        // 焦点移到第一个结果（可以进一步实现完整的键盘导航）
        const firstResult = document.querySelector('.results-container li a') as HTMLElement
        firstResult?.focus()
    }
}

// 处理从插件视图接收的消息
const handlePluginMessage = (...args: unknown[]) => {
    const event = args[0] as any;
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
    const event = args[0] as any;
    const message = args[1] as { viewId: string };

    console.log(`插件视图请求关闭: ${message.viewId}`)
    closePluginView()
}

// 关闭当前插件视图
const closePluginView = () => {
    appState.selectedAction = null
}

// 向当前打开的插件视图发送消息
const sendMessageToPlugin = (channel: string, data: any) => {
    if (!appState.selectedAction) {
        console.warn('没有选中的动作，无法发送消息')
        return
    }

    // 从ActionView组件引用获取当前视图ID
    const viewId = actionView.value?.currentViewId

    if (!viewId) {
        console.warn('无法获取当前视图ID')
        return
    }

    window.electron.send('host-to-plugin', {
        viewId,
        channel,
        data
    })
}

// 在组件加载时注册消息监听
onMounted(() => {
    // 注册接收插件消息的处理函数
    window.electron.receive('plugin-message', handlePluginMessage)
    // 注册插件视图请求关闭的处理函数
    window.electron.receive('plugin-close-requested', handlePluginCloseRequest)
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
    <div class="app-container h-screen flex flex-col justify-center items-center bg-base-100 text-base-content w-full"
        :class="{ 'spotlight-mode': isSpotlightMode }">
        <TitleBar v-if="!isSpotlightMode" />

        <!-- 插件管理器 -->
        <PluginManager ref="pluginManager" />

        <!-- 主容器 -->
        <div class="main-content flex-1 flex flex-col overflow-hidden p-4 max-w-3xl mx-auto w-full">
            <!-- 主界面 -->
            <div v-if="showMainInterface" class="flex-1 flex flex-col">
                <!-- 搜索框组件 -->
                <SearchBar placeholder="搜索Git命令、NPM操作或VS Code功能..." @search="handleSearch" @input="handleInput"
                    @keydown="handleKeyDown" />

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
                    <PluginActionList :actions="pluginManager?.pluginActions || []" :searchKeyword="searchKeyword"
                        @execute="executePluginAction" />
                </div>
            </div>

            <!-- 插件商店 -->
            <div v-if="showPluginStore" class="flex-1 overflow-hidden">
                <PluginStore />
            </div>
        </div>

        <!-- 状态栏 -->
        <StatusBar v-if="!isSpotlightMode" :gitRepo="statusInfo.gitRepo" :branch="statusInfo.branch"
            :commits="statusInfo.commits" :lastUpdated="statusInfo.lastUpdated">
            <template #right>
                <button @click="togglePluginStore" class="btn btn-xs btn-ghost">
                    <i class="i-mdi-package-variant mr-1"></i>
                    插件
                </button>
            </template>
        </StatusBar>
    </div>
</template>

<style scoped>
.app-container {
    position: relative;
}

.main-content {
    width: 100%;
    max-width: 900px;
}

/* Spotlight样式 */
.spotlight-mode {
    background-color: transparent !important;
}

.spotlight-mode .main-content {
    background-color: rgba(30, 30, 30, 0.8);
    border-radius: 12px;
    box-shadow: 0 10px 25px rgba(0, 0, 0, 0.3);
    backdrop-filter: blur(12px);
    -webkit-backdrop-filter: blur(12px);
    padding: 12px;
}

.spotlight-mode :deep(.search-container input) {
    border-radius: 8px;
    background-color: rgba(75, 75, 75, 0.5);
    border: none;
    color: white;
}

.spotlight-mode :deep(.plugin-action-list) {
    color: white;
}

.spotlight-mode :deep(.plugin-action-item) {
    background-color: rgba(75, 75, 75, 0.3);
    margin-bottom: 4px;
    border-radius: 6px;
    transition: background-color 0.2s;
}

.spotlight-mode :deep(.plugin-action-item:hover) {
    background-color: rgba(100, 100, 100, 0.5);
}
</style>
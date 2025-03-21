<script setup lang="ts">
import { ref, reactive, computed } from 'vue'
import TitleBar from './components/TitleBar.vue'
import SearchBar from './components/SearchBar.vue'
import PluginActionList from './components/PluginActionList.vue'
import StatusBar from './components/StatusBar.vue'
import PluginManager from './components/PluginManager.vue'
import PluginStore from './components/PluginStore.vue'
import ActionView from './components/ActionView.vue'
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

// 计算属性：是否显示主界面
const showMainInterface = computed(() => !appState.showPluginStore || !!appState.selectedAction)
// 计算属性：是否显示插件商店
const showPluginStore = computed(() => appState.showPluginStore && !appState.selectedAction)
// 计算属性：是否显示动作视图
const showActionView = computed(() => !!appState.selectedAction)
</script>

<template>
    <div class="app-container h-screen flex flex-col justify-center items-center bg-base-100 text-base-content w-full">
        <TitleBar />

        <!-- 插件管理器 -->
        <PluginManager ref="pluginManager" />

        <div class="main-container flex-1 flex flex-col overflow-hidden p-4 max-w-3xl mx-auto w-full">
            <!-- 主界面 -->
            <div v-if="showMainInterface" class="flex-1 flex flex-col">
                <!-- 搜索框组件 -->
                <SearchBar placeholder="搜索Git命令、NPM操作或VS Code功能..." @search="handleSearch" @input="handleInput"
                    @keydown="handleKeyDown" />

                <!-- 动作视图（如果有选中的动作） -->
                <div v-if="showActionView" class="flex-1 mt-4 overflow-hidden">
                    <ActionView :action="appState.selectedAction" />
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

            <!-- 状态栏组件 -->
            <StatusBar :gitRepo="statusInfo.gitRepo" :branch="statusInfo.branch" :commits="statusInfo.commits"
                :lastUpdated="statusInfo.lastUpdated" class="mt-4">
                <!-- 状态栏右侧额外内容，添加插件商店按钮 -->
                <template #right>
                    <button @click="togglePluginStore" class="btn btn-sm btn-ghost"
                        :class="{ 'btn-active': appState.showPluginStore }">
                        <i class="i-mdi-puzzle-outline mr-1"></i>
                        插件商店
                    </button>
                </template>
            </StatusBar>
        </div>
    </div>
</template>

<style scoped>
.main-container {
    max-height: calc(100vh - 32px);
    /* 减去TitleBar的高度 */
}
</style>
<script setup lang="ts">
import { ref, onMounted, provide, computed } from 'vue'

// 日志函数 - 使用renderer中更友好的格式
const logInfo = (message: string, ...args: any[]) => {
    console.info(`%c[PluginManager] ${message}`, 'color: #4CAF50', ...args)
}

const logError = (message: string, ...args: any[]) => {
    console.error(`%c[PluginManager] ${message}`, 'color: #F44336', ...args)
}

const logDebug = (message: string, ...args: any[]) => {
    console.debug(`%c[PluginManager] ${message}`, 'color: #2196F3', ...args)
}

// 定义插件动作类型
export interface PluginAction {
    id: string
    title: string
    description: string
    icon: string
    plugin: string
    viewPath?: string
    viewMode?: 'embedded' | 'window' // 添加视图模式：embedded-内嵌, window-独立窗口
    devTools?: boolean // 是否启用开发者工具
}

// 插件管理器接口
export interface PluginManagerAPI {
    actions: Readonly<PluginAction[]>
    keyword: Readonly<string>
    isLoading: Readonly<boolean>
    selectedAction: Readonly<PluginAction | null>
    actionViewHtml: Readonly<string>
    loadActions: (keyword?: string) => Promise<PluginAction[]>
    executeAction: (actionId: string) => Promise<any>
    loadActionView: (actionId: string) => Promise<void>
}

// 存储从主进程获取的插件动作数据
const pluginActions = ref<PluginAction[]>([])
// 存储当前的搜索关键词
const currentKeyword = ref('')
// 存储是否正在加载动作
const isLoadingActions = ref(false)
// 存储当前选中的动作
const selectedAction = ref<PluginAction | null>(null)
// 存储当前动作的自定义视图HTML
const actionViewHtml = ref('')

// 加载插件动作
const loadPluginActions = async (keyword: string = ''): Promise<PluginAction[]> => {
    logInfo(`加载插件动作，关键词: "${keyword}"`)
    try {
        isLoadingActions.value = true
        currentKeyword.value = keyword

        // 使用API获取插件动作
        logDebug('调用window.electron.plugins.getPluginActions')
        const actions = await window.electron.plugins.getPluginActions(keyword)
        logInfo(`获取到 ${actions.length} 个插件动作`)
        pluginActions.value = actions
        return actions
    } catch (error) {
        logError('获取插件数据失败:', error)
        pluginActions.value = []
        return []
    } finally {
        isLoadingActions.value = false
    }
}

// 执行插件动作
const executePluginAction = async (actionId: string): Promise<any> => {
    logInfo(`执行插件动作: ${actionId}`)
    try {
        // 查找动作
        const action = pluginActions.value.find(a => a.id === actionId)
        if (!action) {
            const errorMsg = `未找到动作: ${actionId}`
            logError(errorMsg)
            throw new Error(errorMsg)
        }

        logDebug(`找到动作: ${action.id} (${action.title}), 来自插件: ${action.plugin}`)

        // 设置当前选中的动作
        selectedAction.value = action

        // 如果动作有自定义视图，加载视图内容
        if (action.viewPath) {
            logDebug(`动作有自定义视图: ${action.viewPath}，开始加载视图内容`)
            await loadActionView(actionId)
        } else {
            logDebug('动作没有自定义视图')
            actionViewHtml.value = ''
        }

        // 执行动作
        logDebug(`调用window.electron.plugins.executeAction: ${actionId}`)
        const result = await (window.electron.plugins as any).executeAction(actionId)
        logInfo(`动作执行成功: ${actionId}`)
        return result
    } catch (error) {
        logError(`执行插件动作失败: ${error}`)
        throw error
    }
}

// 加载动作的自定义视图
const loadActionView = async (actionId: string): Promise<void> => {
    logInfo(`加载动作视图: ${actionId}`)
    try {
        // 清空之前的视图HTML
        actionViewHtml.value = ''

        // 检查动作是否存在
        const action = pluginActions.value.find(a => a.id === actionId)
        if (!action) {
            throw new Error(`未找到动作: ${actionId}`)
        }

        // 检查动作是否有视图路径
        if (!action.viewPath) {
            throw new Error(`动作 ${actionId} 没有视图路径`)
        }

        logDebug(`调用window.electron.plugins.getActionView: ${actionId}`)
        const response = await (window.electron.plugins as any).getActionView(actionId)

        if (response.success && response.html) {
            logInfo(`成功获取视图HTML，长度: ${response.html.length} 字节`)
            // 确保设置HTML内容
            actionViewHtml.value = response.html

            // 再次确认HTML内容已设置
            if (!actionViewHtml.value) {
                logError('设置视图HTML失败: 赋值后内容为空')
                throw new Error('设置视图HTML失败')
            }

            logDebug(`设置视图HTML成功，当前长度: ${actionViewHtml.value.length}`)
        } else {
            logError(`获取视图HTML失败: ${response.error || '未知错误'}`)
            actionViewHtml.value = ''
            if (response.error) {
                throw new Error(response.error)
            }
        }
    } catch (error) {
        logError(`加载动作视图失败: ${error}`)
        actionViewHtml.value = ''
        throw error
    }
}

// 初始化时加载插件动作
onMounted(() => {
    logInfo('PluginManager组件已挂载，加载初始插件动作')
    loadPluginActions()
})

// 计算属性，用于暴露给API
const actionsComputed = computed(() => pluginActions.value)
const keywordComputed = computed(() => currentKeyword.value)
const isLoadingComputed = computed(() => isLoadingActions.value)
const selectedActionComputed = computed(() => selectedAction.value)
const actionViewHtmlComputed = computed(() => actionViewHtml.value)

// 插件管理器接口
const pluginManagerAPI: PluginManagerAPI = {
    // 获取动作列表
    get actions() { return actionsComputed.value },

    // 当前关键词
    get keyword() { return keywordComputed.value },

    // 是否正在加载
    get isLoading() { return isLoadingComputed.value },

    // 当前选中的动作
    get selectedAction() { return selectedActionComputed.value },

    // 当前动作的自定义视图HTML
    get actionViewHtml() { return actionViewHtmlComputed.value },

    // 加载动作
    loadActions: loadPluginActions,

    // 执行动作
    executeAction: executePluginAction,

    // 加载动作视图
    loadActionView: loadActionView
}

// 使用Vue的依赖注入，提供API给子组件
provide('pluginManager', pluginManagerAPI)
logDebug('插件管理器API已通过依赖注入提供给子组件')

// 暴露API给父组件
defineExpose({
    pluginActions,
    currentKeyword,
    isLoadingActions,
    selectedAction,
    actionViewHtml,
    loadPluginActions,
    executeAction: executePluginAction,
    loadActionView
})

logInfo('PluginManager组件初始化完成')
</script>

<template>
    <!-- 插件管理器是一个逻辑组件，不渲染UI -->
    <slot></slot>
</template>
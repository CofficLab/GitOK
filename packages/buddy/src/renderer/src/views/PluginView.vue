/**
* 插件动作视图
*
* 功能：
* 1. 展示选中的插件动作详情
* 2. 显示动作执行结果或在独立的BrowserWindow中显示自定义视图
* 3. 提供返回到动作列表的功能
*/
<script setup lang="ts">
import { ref, inject, watch, onUnmounted, reactive } from 'vue'
import type { PluginManagerAPI, PluginAction } from '@renderer/components/PluginManager.vue'

// 定义辅助函数获取插件视图API
const getPluginViewsAPI = () => (window.electron.plugins as any).views

// 接收传入的动作ID和返回回调
const props = defineProps<{
    actionId: string
}>()

const emit = defineEmits<{
    back: []
}>()

// 插件管理器API
const pluginManager = inject<PluginManagerAPI>('pluginManager')

// 当前选中的动作
const selectedAction = ref<PluginAction | null>(null)
// 是否正在加载动作视图
const isLoading = ref(false)
// 动作执行的结果
const actionResult = ref<any>(null)
// 是否发生错误
const hasError = ref(false)
// 错误信息
const errorMessage = ref('')
// 插件视图窗口状态
const pluginViewState = reactive({
    id: '',
    isOpen: false
})
// 内嵌视图HTML
const embeddedViewHtml = ref('')

// 加载并执行动作
const loadAndExecuteAction = async () => {
    if (!pluginManager) return

    const actionId = props.actionId
    isLoading.value = true
    hasError.value = false
    errorMessage.value = ''
    embeddedViewHtml.value = ''
    actionResult.value = null

    // 如果有之前打开的视图窗口，关闭它
    await closePluginWindow()

    try {
        // 查找动作信息
        const action = pluginManager.actions.find(a => a.id === actionId)
        if (!action) {
            throw new Error(`未找到动作: ${actionId}`)
        }

        selectedAction.value = action
        console.log(`PluginView: 加载动作 ${action.title}`)

        // 执行动作
        const result = await pluginManager.executeAction(actionId)
        actionResult.value = result
        console.log(`PluginView: 动作执行结果:`, result)

        // 如果有视图路径，根据viewMode决定显示方式
        if (action.viewPath) {
            console.log(`PluginView: 动作有视图路径: ${action.viewPath}, 视图模式: ${action.viewMode || 'embedded'}`)
            const viewMode = action.viewMode || 'embedded' // 默认使用内嵌模式

            if (viewMode === 'window') {
                // 在独立窗口中显示
                console.log(`PluginView: 使用独立窗口模式显示`)
                await openPluginWindow(actionId, action)
            } else {
                // 在应用内嵌入显示 - 直接尝试从pluginManager获取HTML内容
                console.log(`PluginView: 使用内嵌模式显示`)

                // 使用直接获取的方式获取视图内容
                if (pluginManager.actionViewHtml) {
                    console.log(`PluginView: 从pluginManager直接获取到HTML，长度: ${pluginManager.actionViewHtml.length}`)
                    embeddedViewHtml.value = pluginManager.actionViewHtml
                } else {
                    console.log(`PluginView: pluginManager中没有HTML内容，尝试重新加载视图`)
                    // 如果没有内容，重新调用loadActionView
                    try {
                        await pluginManager.loadActionView(actionId)
                        await new Promise(resolve => setTimeout(resolve, 100)) // 短暂等待
                        if (pluginManager.actionViewHtml) {
                            embeddedViewHtml.value = pluginManager.actionViewHtml
                            console.log(`PluginView: 重新加载后获取到HTML，长度: ${embeddedViewHtml.value.length}`)
                        } else {
                            // 如果依然没有，尝试调用renderer的API直接获取
                            console.log(`PluginView: 依然没有HTML内容，尝试直接调用API`)
                            const viewResponse = await (window.electron.plugins as any).getActionView(actionId)
                            if (viewResponse && viewResponse.success && viewResponse.html) {
                                embeddedViewHtml.value = viewResponse.html
                                console.log(`PluginView: 通过API直接获取到HTML，长度: ${embeddedViewHtml.value.length}`)
                            } else {
                                console.log(`PluginView: 无法通过任何方式获取HTML内容`)
                                throw new Error('无法获取视图HTML内容')
                            }
                        }
                    } catch (viewError) {
                        console.error(`PluginView: 加载视图失败:`, viewError)
                        throw viewError
                    }
                }
            }
        } else {
            console.log(`PluginView: 动作没有视图路径，只显示结果`)
        }
    } catch (error) {
        const errorMsg = error instanceof Error ? error.message : String(error)
        console.error(`PluginView: 执行动作失败: ${errorMsg}`)
        hasError.value = true
        errorMessage.value = errorMsg
    } finally {
        isLoading.value = false
    }
}

// 在应用内嵌入显示视图
const loadEmbeddedView = async (actionId: string) => {
    try {
        console.log(`PluginView: 开始加载内嵌视图，动作ID: ${actionId}`)

        if (!pluginManager) {
            throw new Error('插件管理器未初始化')
        }

        // 先清空旧的视图内容
        actionResult.value = null
        embeddedViewHtml.value = ''

        // 重新调用loadActionView，确保能获取最新的视图内容
        await pluginManager.loadActionView(actionId)

        // 等待一小段时间确保视图内容已加载完成
        await new Promise(resolve => setTimeout(resolve, 100))

        // 从pluginManager获取视图HTML
        const viewHtml = pluginManager.actionViewHtml
        console.log(`PluginView: 获取到视图HTML，长度: ${viewHtml?.length || 0}`)

        if (viewHtml) {
            embeddedViewHtml.value = viewHtml
            console.log(`PluginView: 加载内嵌视图HTML完成，长度: ${embeddedViewHtml.value.length}`)
        } else {
            console.log(`PluginView: 视图内容为空`)
            throw new Error('获取到的视图内容为空')
        }
    } catch (error) {
        const errorMsg = error instanceof Error ? error.message : String(error)
        console.error(`PluginView: 加载内嵌视图失败: ${errorMsg}`)
        hasError.value = true
        errorMessage.value = `加载内嵌视图失败: ${errorMsg}`
    }
}

// 在独立窗口中打开插件视图
const openPluginWindow = async (actionId: string, action: PluginAction) => {
    try {
        // 使用动作ID作为视图ID
        pluginViewState.id = `plugin-view-${actionId}`

        // 获取插件视图API
        const viewsAPI = getPluginViewsAPI()

        // 获取主窗口位置和大小以便设置插件窗口的位置
        const mainWindowBounds = await viewsAPI.create(
            pluginViewState.id,
            `plugin-view://${actionId}` // 确保actionId格式正确
        )

        if (mainWindowBounds) {
            // 在主窗口旁边显示插件窗口
            await viewsAPI.show(pluginViewState.id, {
                x: mainWindowBounds.x + mainWindowBounds.width,
                y: mainWindowBounds.y,
                width: 600,
                height: mainWindowBounds.height
            })

            pluginViewState.isOpen = true
            console.log(`PluginView: 插件视图窗口已打开: ${pluginViewState.id}`)
        }
    } catch (error) {
        const errorMsg = error instanceof Error ? error.message : String(error)
        console.error(`PluginView: 打开插件视图窗口失败: ${errorMsg}`)
        hasError.value = true
        errorMessage.value = `打开插件视图失败: ${errorMsg}`
    }
}

// 关闭插件视图窗口
const closePluginWindow = async () => {
    if (pluginViewState.isOpen && pluginViewState.id) {
        try {
            await getPluginViewsAPI().destroy(pluginViewState.id)
            console.log(`PluginView: 插件视图窗口已关闭: ${pluginViewState.id}`)
        } catch (error) {
            console.error(`PluginView: 关闭插件视图窗口失败:`, error)
        } finally {
            pluginViewState.isOpen = false
            pluginViewState.id = ''
        }
    }
}

// 返回动作列表
const goBack = async () => {
    // 关闭插件视图窗口
    await closePluginWindow()
    emit('back')
}

// 组件卸载时关闭插件视图窗口
onUnmounted(() => {
    closePluginWindow()
})

// 在动作ID变化时重新加载
watch(() => props.actionId, (newId) => {
    if (newId) {
        loadAndExecuteAction()
    }
}, { immediate: true })
</script>

<template>
    <div class="plugin-view flex flex-col h-full">
        <!-- 头部 - 标题和返回按钮 -->
        <div class="flex items-center mb-4">
            <button @click="goBack" class="flex items-center text-blue-500 hover:text-blue-700">
                <span class="mr-1">←</span> 返回
            </button>
            <h2 v-if="selectedAction" class="text-xl font-semibold ml-4">{{ selectedAction.title }}</h2>
        </div>

        <!-- 加载中状态 -->
        <div v-if="isLoading" class="flex-1 flex items-center justify-center">
            <p class="text-gray-500">加载中...</p>
        </div>

        <!-- 错误状态 -->
        <div v-else-if="hasError" class="error flex-1 p-4">
            <h3 class="text-red-600 font-medium mb-2">执行动作失败</h3>
            <p>{{ errorMessage }}</p>
        </div>

        <!-- 内嵌视图 -->
        <div v-else-if="embeddedViewHtml" class="flex-1 border rounded-lg p-4 bg-white shadow-sm overflow-auto">
            <div v-html="embeddedViewHtml"></div>
        </div>

        <!-- 插件使用独立窗口显示 -->
        <div v-else-if="pluginViewState.isOpen"
            class="flex-1 flex flex-col items-center justify-center p-6 border rounded-lg border-blue-200 bg-blue-50">
            <p class="text-lg mb-4">插件视图已在独立窗口中打开</p>
            <p class="text-sm text-gray-600 mb-6">该窗口将在您返回动作列表或关闭此页面时自动关闭</p>
            <button @click="closePluginWindow"
                class="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 transition">
                关闭插件窗口
            </button>
        </div>

        <!-- 显示结果（如果没有视图） -->
        <div v-else-if="actionResult && !pluginViewState.isOpen && !embeddedViewHtml"
            class="flex-1 p-4 border rounded-lg bg-gray-50 overflow-auto">
            <pre class="whitespace-pre-wrap">{{ JSON.stringify(actionResult, null, 2) }}</pre>
        </div>

        <!-- 空状态 -->
        <div v-else class="flex-1 flex items-center justify-center text-gray-500">
            <p>未加载任何动作</p>
        </div>
    </div>
</template>

<style scoped>
.error {
    color: #e53e3e;
    padding: 1rem;
    border: 1px solid #feb2b2;
    border-radius: 0.5rem;
    background-color: #fff5f5;
}
</style>
/**
* 插件动作视图
*
* 功能：
* 1. 展示选中的插件动作详情
* 2. 显示动作执行结果或在独立的BrowserWindow中显示自定义视图
* 3. 提供返回到动作列表的功能
*/
<script setup lang="ts">
import { ref, watch, onUnmounted, reactive, onMounted, nextTick, computed } from 'vue'
import { useActionStore } from '@renderer/stores/actionStore'
import { logger } from '@renderer/utils/logger'
import { SuperAction, ViewBounds } from '@coffic/buddy-types'
import { pluginIpc } from '../api/plugin-ipc'

const actionStore = useActionStore()

const emit = defineEmits<{
    back: []
}>()

// 当前选中的动作
const selectedAction = computed(() => actionStore.getSelectedAction())
// 是否正在加载动作视图
const isLoading = computed(() => actionStore.isLoading)
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
// 内嵌视图状态
const embeddedViewState = reactive({
    id: '',
    isAttached: false,
    isVisible: false,
    content: ''
})
// 嵌入式视图容器引用
const embeddedViewContainer = ref<HTMLDivElement | null>(null)

// 加载并执行动作
const loadAndExecuteAction = async () => {
    const actionId = actionStore.getSelectedActionId()
    if (!actionId) return

    hasError.value = false
    errorMessage.value = ''
    actionResult.value = null

    // 如果有之前打开的视图，关闭它
    await closePluginWindow()
    await destroyEmbeddedView()

    // 查找动作信息
    const action = actionStore.find(actionId)
    if (!action) {
        throw new Error(`未找到动作: ${actionId}`)
    }

    try {
        const result = await actionStore.execute(action.globalId)
        actionResult.value = result

        // 如果有视图路径，根据viewMode决定显示方式
        if (action.viewPath) {
            const viewMode = action.viewMode || 'embedded' // 默认使用内嵌模式

            if (viewMode === 'window') {
                await openPluginWindow(actionId, action)
            } else {
                await createEmbeddedView(actionId, action)
            }
        }
    } catch (error) {
        const errorMsg = error instanceof Error ? error.message : String(error)
        logger.error(`PluginView: 执行动作失败: ${errorMsg}`)
        hasError.value = true
        errorMessage.value = errorMsg
    }
}

// 创建并显示嵌入式视图
const createEmbeddedView = async (actionId: string, action: SuperAction) => {
    try {
        // 使用动作ID作为视图ID
        embeddedViewState.id = `embedded-view-${actionId}`

        // 获取主进程存储的HTML内容
        embeddedViewState.content = actionStore.viewHtml
        logger.info(`PluginView: 获取到视图HTML内容，长度: ${embeddedViewState.content?.length || 0}`)

        // 清除可能存在的错误状态，确保条件渲染逻辑正确
        hasError.value = false
        errorMessage.value = ''

        // 首先将视图状态设置为已附加，这样模板会渲染出容器
        embeddedViewState.isAttached = true
        logger.info('PluginView: 设置视图状态为已附加，准备渲染容器...')

        // 等待下一个渲染周期完成
        await nextTick()

        // 增加一个小延迟，让DOM有足够时间渲染
        await new Promise(resolve => setTimeout(resolve, 50));

        // 等待DOM完全渲染
        // 增加一个循环来确保容器已渲染，最多尝试10次，每次等待100ms
        let attempts = 0;
        const maxAttempts = 20; // 增加最大尝试次数
        while (!embeddedViewContainer.value && attempts < maxAttempts) {
            await new Promise(resolve => setTimeout(resolve, 50)); // 减少等待时间，增加频率
            attempts++;
            logger.info(`PluginView: 等待容器渲染，尝试 ${attempts}/${maxAttempts}`);
            // 强制刷新一下DOM引用
            await nextTick();
        }

        // 确保容器已渲染
        if (!embeddedViewContainer.value) {
            logger.error('PluginView: 视图容器不存在，无法创建视图');
            throw new Error('嵌入式视图容器不存在');
        }

        logger.info('PluginView: 容器已渲染，准备创建嵌入式视图');

        // 获取容器位置和尺寸
        const container = embeddedViewContainer.value
        const rect = container.getBoundingClientRect()

        // 确保所有值都是整数，并且至少有合理的尺寸
        const bounds: ViewBounds = {
            x: Math.max(0, Math.round(rect.left)),
            y: Math.max(0, Math.round(rect.top)),
            width: Math.max(100, Math.round(rect.width)),
            height: Math.max(100, Math.round(rect.height))
        }

        logger.info(`PluginView: 创建嵌入式视图: ${embeddedViewState.id}，容器边界: ${bounds}`)

        try {
            // 首先创建嵌入式视图
            const mainWindowBounds = await pluginIpc.createView(
                embeddedViewState.id,
                `plugin-view://${actionId}`
            )

            logger.info(`PluginView: 嵌入式视图已创建，主窗口边界: ${mainWindowBounds}`)

            // 现在显示嵌入式视图，传递容器边界
            const showResult = await pluginIpc.showView(embeddedViewState.id, bounds)
            if (!showResult) {
                throw new Error('显示嵌入式视图失败')
            }

            logger.info(`PluginView: 嵌入式视图已显示，边界: ${bounds}`)
            embeddedViewState.isVisible = true

            // 如果动作指定了开启开发者工具，则自动打开
            if (action.devTools) {
                setTimeout(async () => {
                    try {
                        logger.info(`PluginView: 准备打开开发者工具: ${embeddedViewState.id}`)
                        const result = await pluginIpc.toggleDevTools(embeddedViewState.id)
                        logger.info(`PluginView: 开发者工具打开结果: ${result}`)
                    } catch (devToolsError) {
                        logger.error(`PluginView: 打开开发者工具失败: ${devToolsError}`)
                    }
                }, 1000)
            }
        } catch (viewError) {
            // 处理视图创建或显示过程中的错误
            logger.error(`PluginView: 视图操作失败: ${viewError}`);
            throw viewError;
        }
    } catch (error) {
        const errorMsg = error instanceof Error ? error.message : String(error)
        logger.error(`PluginView: 创建嵌入式视图失败: ${errorMsg}`)

        // 重置视图状态
        embeddedViewState.isAttached = false
        embeddedViewState.isVisible = false

        hasError.value = true
        errorMessage.value = `创建嵌入式视图失败: ${errorMsg}`
    }
}

// 销毁嵌入式视图
const destroyEmbeddedView = async () => {
    if (embeddedViewState.id) {
        try {
            await pluginIpc.destroyView(embeddedViewState.id)
            logger.info(`PluginView: 嵌入式视图已销毁: ${embeddedViewState.id}`)
        } catch (error) {
            logger.error(`PluginView: 销毁嵌入式视图失败: ${error}`)
        } finally {
            embeddedViewState.id = ''
            embeddedViewState.isAttached = false
            embeddedViewState.isVisible = false
            embeddedViewState.content = ''
        }
    }
}

// 在独立窗口中打开插件视图
const openPluginWindow = async (actionId: string, _action: SuperAction) => {
    try {
        // 使用动作ID作为视图ID
        pluginViewState.id = `plugin-view-${actionId}`

        // 获取主窗口位置和大小以便设置插件窗口的位置
        await pluginIpc.createView(
            pluginViewState.id,
            `plugin-view://${actionId}`, // 确保actionId格式正确
        )
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
            await pluginIpc.destroyView(pluginViewState.id)
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
    await closePluginWindow()
    await destroyEmbeddedView()
    emit('back')
}

// 设置嵌入式视图事件监听器的清理函数
const cleanupFunctions: (() => void)[] = [];

// 在组件卸载时清理所有事件监听器
onUnmounted(() => {
    console.log('PluginView: 组件卸载，清理事件监听器');

    // 销毁嵌入式视图
    destroyEmbeddedView();

    // 清理所有监听器
    cleanupFunctions.forEach(cleanup => {
        try {
            cleanup();
        } catch (error) {
            console.error('PluginView: 清理事件监听器失败:', error);
        }
    });

    // 清空数组
    cleanupFunctions.length = 0;
});

// 在动作ID变化时重新加载
watch(() => actionStore.getSelectedActionId(), (newId) => {
    if (newId) {
        loadAndExecuteAction()
    }
})

// 组件挂载时加载动作
onMounted(() => {
    const actionId = actionStore.getSelectedActionId()
    if (actionId) {
        loadAndExecuteAction()
    }
})
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

        <!-- 内嵌视图容器 - 始终存在但仅在需要时显示 -->
        <div ref="embeddedViewContainer"
            class="flex-1 border rounded-lg bg-white shadow-sm overflow-hidden embedded-view-container"
            :class="{ 'hidden': !embeddedViewState.isAttached }"
            style="min-height: 400px; position: relative; z-index: 1;">
            <div class="debug-info p-4 text-xs text-gray-500">
                <div><strong>视图信息:</strong> {{ selectedAction?.title }} ({{ selectedAction?.id }})</div>
                <div><strong>视图模式:</strong> 内嵌式BrowserView</div>
                <div><strong>视图ID:</strong> {{ embeddedViewState.id }}</div>
                <div v-if="embeddedViewState.isVisible"><strong>状态:</strong> 可见</div>
                <div v-else><strong>状态:</strong> 正在加载...</div>
            </div>
        </div>

        <!-- 插件使用独立窗口显示 -->
        <div v-if="!embeddedViewState.isAttached && pluginViewState.isOpen"
            class="flex-1 flex flex-col items-center justify-center p-6 border rounded-lg border-blue-200 bg-blue-50">
            <p class="text-lg mb-4">插件视图已在独立窗口中打开</p>
            <p class="text-sm text-gray-600 mb-6">该窗口将在您返回动作列表或关闭此页面时自动关闭</p>
            <button @click="closePluginWindow"
                class="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 transition">
                关闭插件窗口
            </button>
        </div>

        <!-- 显示结果（如果没有视图） -->
        <div v-if="!embeddedViewState.isAttached && !pluginViewState.isOpen && actionResult"
            class="flex-1 p-4 border rounded-lg bg-gray-50 overflow-auto">
            <pre class="whitespace-pre-wrap">{{ JSON.stringify(actionResult, null, 2) }}</pre>
        </div>

        <!-- 空状态 -->
        <div v-if="!embeddedViewState.isAttached && !pluginViewState.isOpen && !actionResult && !isLoading && !hasError"
            class="flex-1 flex items-center justify-center text-gray-500">
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

.embedded-view-container {
    display: flex;
    flex-direction: column;
    min-height: 400px;
    position: relative;
    z-index: 1;
}

.embedded-view-container.hidden {
    display: none;
}

/* 在调试信息下方预留空间，让实际内容区域不被遮挡 */
.embedded-view-container .debug-info {
    position: relative;
    z-index: 10;
    background-color: rgba(255, 255, 255, 0.8);
    border-bottom: 1px solid #eee;
    padding: 12px;
}
</style>
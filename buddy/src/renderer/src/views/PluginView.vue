<script setup lang="ts">
import { ref, watch, onUnmounted, onMounted, nextTick } from 'vue'
import { useActionStore } from '@renderer/stores/actionStore'
import { logger } from '@renderer/utils/logger'
import { ViewBounds } from '@coffic/buddy-types'
import { SendableAction } from '@/types/sendable-action'
import { viewIpc } from '../ipc/view-ipc'
import { useElementBounding, useAsyncState, useDebounceFn, useTimeoutFn } from '@vueuse/core'

const actionStore = useActionStore()

// 视图容器引用
const embeddedViewContainer = ref<HTMLDivElement | null>(null)

// 使用useElementBounding自动跟踪容器位置和尺寸
const { x, y, width, height, update: updateBounds } = useElementBounding(embeddedViewContainer)

// 视图状态
const viewState = ref({
    // 嵌入式视图状态
    embedded: {
        id: '',
        isAttached: false,
        isVisible: false,
        content: ''
    },
    // 窗口视图状态
    window: {
        id: '',
        isOpen: false
    },
    // 当前活动的动作
    currentAction: null as SendableAction | null
})

// 处理错误
function handleError(error: unknown): string {
    const errorMsg = error instanceof Error ? error.message : String(error)
    logger.error(`PluginView: 执行动作失败: ${errorMsg}`)
    return errorMsg
}

// 创建增强的执行动作函数
const { isLoading, state: actionResult, error: actionError } = useAsyncState(
    async (actionId: string) => {
        // 重置状态
        await destroyViews()
        viewState.value = {
            embedded: {
                id: '',
                isAttached: false,
                isVisible: false,
                content: ''
            },
            window: {
                id: '',
                isOpen: false
            },
            currentAction: null
        }

        // 查找动作信息
        const action = actionStore.find(actionId)
        if (!action) {
            throw new Error(`未找到动作: ${actionId}`)
        }

        viewState.value.currentAction = action

        // 执行动作
        const result = await actionStore.execute(action.globalId)

        // 如果有视图路径，根据viewMode决定显示方式
        if (action.viewPath) {
            const viewMode = action.viewMode || 'embedded' // 默认使用内嵌模式

            if (viewMode === 'window') {
                await openPluginWindow(action)
            } else {
                await createEmbeddedView(action)
            }
        }

        return result
    },
    null,
    { immediate: false, resetOnExecute: true, onError: handleError }
)

// 防抖的边界更新函数，用于窗口大小调整或滚动时
const debouncedUpdateViewBounds = useDebounceFn(async () => {
    // 只有在嵌入式视图时才更新
    if (viewState.value.embedded.isAttached && viewState.value.currentAction?.viewPath) {
        updateBounds()
        await updateViewPosition()
    }
}, 100)

// 更新视图位置
const updateViewPosition = async () => {
    if (!viewState.value.currentAction?.viewPath || !viewState.value.embedded.isAttached) return

    try {
        // 确保数值有效且为整数
        const bounds = {
            x: Math.max(0, Math.round(x.value)),
            y: Math.max(0, Math.round(y.value)),
            width: Math.max(100, Math.round(width.value)),
            height: Math.max(100, Math.round(height.value))
        }

        await viewIpc.upsertView({
            pagePath: viewState.value.currentAction.viewPath,
            x: bounds.x,
            y: bounds.y,
            width: bounds.width,
            height: bounds.height
        })
    } catch (error) {
        logger.error(`PluginView: 更新视图位置失败: ${error}`)
    }
}

// 创建嵌入式视图的延迟函数，避免DOM渲染问题
const { start: startCreateEmbeddedView } = useTimeoutFn(createEmbeddedViewImmediate, 100)

// 创建并显示嵌入式视图
async function createEmbeddedView(action: SendableAction) {
    // 设置视图ID
    viewState.value.embedded.id = `embedded-view-${action.globalId}`

    // 获取主进程存储的HTML内容
    viewState.value.embedded.content = actionStore.viewHtml

    // 设置为已附加状态，这样模板会渲染容器
    viewState.value.embedded.isAttached = true

    logger.info('PluginView: 设置视图状态为已附加，准备渲染容器...')

    // 等待下一个渲染周期，确保DOM更新
    await nextTick()

    // 使用延迟函数创建视图，避免DOM渲染未完成问题
    startCreateEmbeddedView()
}

// 实际创建嵌入式视图的函数
async function createEmbeddedViewImmediate() {
    if (!embeddedViewContainer.value || !viewState.value.currentAction?.viewPath) {
        logger.error('PluginView: 视图容器不存在或视图路径无效')
        return
    }

    try {
        // 强制更新边界数据
        updateBounds()

        // 确保所有值都是整数，并且至少有合理的尺寸
        const bounds: ViewBounds = {
            x: Math.max(0, Math.round(x.value)),
            y: Math.max(0, Math.round(y.value)),
            width: Math.max(100, Math.round(width.value)),
            height: Math.max(100, Math.round(height.value))
        }

        logger.info(`PluginView: 创建嵌入式视图: ${viewState.value.embedded.id}，容器边界: ${JSON.stringify(bounds)}`)

        await viewIpc.upsertView({
            pagePath: viewState.value.currentAction.viewPath,
            x: bounds.x,
            y: bounds.y,
            width: bounds.width,
            height: bounds.height
        })

        viewState.value.embedded.isVisible = true

        // 设置事件监听器，处理窗口大小变化
        window.addEventListener('resize', debouncedUpdateViewBounds)
        document.addEventListener('scroll', debouncedUpdateViewBounds)
    } catch (error) {
        const errorMsg = error instanceof Error ? error.message : String(error)
        logger.error(`PluginView: 创建嵌入式视图失败: ${errorMsg}`)

        // 重置视图状态
        viewState.value.embedded.isAttached = false
        viewState.value.embedded.isVisible = false

        throw new Error(`创建嵌入式视图失败: ${errorMsg}`)
    }
}

// 销毁视图
const destroyViews = async () => {
    try {
        await viewIpc.destroyViews()
        logger.info(`PluginView: 视图已销毁: ${viewState.value.embedded.id}`)
    } catch (error) {
        logger.error(`PluginView: 销毁视图失败: ${error}`)
    } finally {
        // 移除事件监听器
        window.removeEventListener('resize', debouncedUpdateViewBounds)
        document.removeEventListener('scroll', debouncedUpdateViewBounds)

        // 重置视图状态
        viewState.value.embedded.id = ''
        viewState.value.embedded.isAttached = false
        viewState.value.embedded.isVisible = false
        viewState.value.embedded.content = ''
        viewState.value.window.isOpen = false
        viewState.value.window.id = ''
    }
}

// 在独立窗口中打开插件视图
const openPluginWindow = async (action: SendableAction) => {
    try {
        viewState.value.window.id = `window-view-${action.globalId}`

        // 获取主窗口位置和大小以便设置插件窗口的位置
        await viewIpc.upsertView({
            pagePath: action.viewPath!,
            x: 100,
            y: 100,
            width: 400,
            height: 400,
        })

        viewState.value.window.isOpen = true
    } catch (error) {
        const errorMsg = error instanceof Error ? error.message : String(error)
        logger.error(`PluginView: 打开插件视图窗口失败: ${errorMsg}`)
        throw new Error(`打开插件视图失败: ${errorMsg}`)
    }
}

// 返回动作列表
const goBack = async () => {
    await destroyViews()
    actionStore.clearWillRun()
}

// 加载并执行动作
const loadAndExecuteAction = () => {
    const actionId = actionStore.getSelectedActionId()
    if (!actionId) return

    // 手动调用异步函数而不使用execute方法
    destroyViews().then(() => {
        const action = actionStore.find(actionId)
        if (action) {
            // 手动实现原来executeAction的逻辑
            viewState.value.currentAction = action

            actionStore.execute(action.globalId).then(() => {
                if (action.viewPath) {
                    const viewMode = action.viewMode || 'embedded'

                    if (viewMode === 'window') {
                        openPluginWindow(action)
                    } else {
                        createEmbeddedView(action)
                    }
                }
            }).catch(error => {
                logger.error(`PluginView: 执行动作失败: ${error}`)
            })
        }
    })
}

// 在动作ID变化时重新加载
watch(() => actionStore.willRun, (newId) => {
    if (newId) {
        loadAndExecuteAction()
    }
})

// 组件卸载时清理资源
onUnmounted(() => {
    logger.info('PluginView: 组件卸载，清理资源')

    // 移除事件监听器
    window.removeEventListener('resize', debouncedUpdateViewBounds)
    document.removeEventListener('scroll', debouncedUpdateViewBounds)

    // 销毁视图
    destroyViews()
})

// 组件挂载时加载动作
onMounted(() => {
    const actionId = actionStore.willRun
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
        </div>

        <!-- 加载中状态 -->
        <div v-if="isLoading" class="flex-1 flex items-center justify-center">
            <p class="text-gray-500">加载中...</p>
        </div>

        <!-- 错误状态 -->
        <div v-else-if="actionError" class="error flex-1 p-4">
            <h3 class="text-red-600 font-medium mb-2">执行动作失败</h3>
            <p>{{ actionError }}</p>
        </div>

        <!-- 内嵌视图容器 - 始终存在但仅在需要时显示 -->
        <div ref="embeddedViewContainer"
            class="flex-1 border rounded-lg bg-white shadow-sm overflow-hidden embedded-view-container"
            :class="{ 'hidden': !viewState.embedded.isAttached }"
            style="min-height: 400px; position: relative; z-index: 1;">
        </div>

        <!-- 插件使用独立窗口显示 -->
        <div v-if="!viewState.embedded.isAttached && viewState.window.isOpen"
            class="flex-1 flex flex-col items-center justify-center p-6 border rounded-lg border-blue-200 bg-blue-50">
            <p class="text-lg mb-4">插件视图已在独立窗口中打开</p>
            <p class="text-sm text-gray-600 mb-6">该窗口将在您返回动作列表或关闭此页面时自动关闭</p>
            <button @click="destroyViews" class="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 transition">
                关闭插件窗口
            </button>
        </div>

        <!-- 显示结果（如果没有视图） -->
        <div v-if="!viewState.embedded.isAttached && !viewState.window.isOpen && actionResult"
            class="flex-1 p-4 border rounded-lg bg-gray-50 overflow-auto">
            <pre class="whitespace-pre-wrap">{{ JSON.stringify(actionResult, null, 2) }}</pre>
        </div>

        <!-- 空状态 -->
        <div v-if="!viewState.embedded.isAttached && !viewState.window.isOpen && !actionResult && !isLoading && !actionError"
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
</style>
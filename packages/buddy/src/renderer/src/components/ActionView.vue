<script setup lang="ts">
import { ref, watch, onMounted, onUnmounted, defineExpose } from 'vue'
import { PluginAction } from './PluginManager.vue'

// 日志函数 - 使用renderer中更友好的格式
const logInfo = (message: string, ...args: any[]) => {
    console.info(`%c[ActionView] ${message}`, 'color: #9C27B0', ...args)
}

const logError = (message: string, ...args: any[]) => {
    console.error(`%c[ActionView] ${message}`, 'color: #F44336', ...args)
}

const logDebug = (message: string, ...args: any[]) => {
    console.debug(`%c[ActionView] ${message}`, 'color: #2196F3', ...args)
}

// 组件属性
const props = defineProps<{
    action: PluginAction | null
}>()

// HTML内容
const htmlContent = ref('')
// 加载状态
const loading = ref(false)
// 错误信息
const error = ref<string | null>(null)
// 当前视图ID
const currentViewId = ref<string | null>(null)
// 是否使用WebContentsView
const useWebContentsView = ref(true)

// 生成唯一的视图ID
const generateViewId = () => {
    const timestamp = Date.now();
    const random = Math.floor(Math.random() * 1000);
    const actionId = props.action?.id || 'unknown';
    return `view_${timestamp}_${actionId}_${random}`;
}

// 创建和显示WebContentsView
const createWebContentsView = async (action: PluginAction): Promise<boolean> => {
    try {
        loading.value = true

        // 先隐藏并销毁当前视图
        if (currentViewId.value) {
            logDebug(`销毁现有视图: ${currentViewId.value}`)
            await window.electron.plugins.views.destroy(currentViewId.value)
            currentViewId.value = null
        }

        // 生成新的视图ID
        const viewId = generateViewId()
        logInfo(`为动作 ${action.id} 创建WebContentsView, 视图ID: ${viewId}`)

        // 如果插件指定了URL，则使用URL
        const url = action.viewPath || ''
        if (!url) {
            logError(`动作没有提供视图路径`)
            return false
        }

        // 创建视图
        const createResult = await window.electron.plugins.views.create(viewId, url)
        if (!createResult.success) {
            logError(`创建视图失败: ${createResult.error}`)
            error.value = createResult.error || '创建视图失败'
            return false
        }

        // 显示视图
        const showResult = await window.electron.plugins.views.show(viewId)
        if (!showResult.success) {
            logError(`显示视图失败: ${showResult.error}`)
            error.value = showResult.error || '显示视图失败'
            return false
        }

        currentViewId.value = viewId
        logInfo(`成功创建并显示视图: ${viewId}`)
        error.value = null
        return true
    } catch (err) {
        const errorMsg = err instanceof Error ? err.message : '创建视图失败'
        logError(`创建WebContentsView失败:`, err)
        error.value = errorMsg
        return false
    } finally {
        loading.value = false
    }
}

// 加载视图内容 - 使用iframe方式
const loadViewContent = async () => {
    logDebug(`loadViewContent被调用，当前动作: ${props.action?.id || 'null'}`)

    if (!props.action || !props.action.viewPath) {
        logDebug('无动作或动作没有视图路径，清空内容')
        htmlContent.value = ''
        return
    }

    // 如果使用WebContentsView，则调用相应方法创建视图
    if (useWebContentsView.value) {
        logDebug('使用WebContentsView渲染视图，跳过HTML内容加载')
        createWebContentsView(props.action)
        return
    }

    try {
        logInfo(`开始加载动作视图内容: ${props.action.id} (${props.action.title})`)
        loading.value = true
        error.value = null

        const response = await window.electron.plugins.getActionView(props.action.id)
        logDebug(`获取视图内容响应: ${JSON.stringify({ success: response.success, hasHtml: !!response.html, error: response.error })}`)

        if (response.success && response.html) {
            logInfo(`成功获取视图HTML，长度: ${response.html.length} 字节`)
            htmlContent.value = response.html
        } else if (response.error) {
            logError(`获取视图内容失败: ${response.error}`)
            error.value = response.error
            htmlContent.value = ''
        }
    } catch (err) {
        const errorMsg = err instanceof Error ? err.message : '加载视图失败'
        logError(`加载视图内容失败:`, err)
        error.value = errorMsg
        htmlContent.value = ''
    } finally {
        loading.value = false
    }
}

// 创建iframe视图
const createIframeView = () => {
    logDebug(`createIframeView被调用，HTML内容长度: ${htmlContent.value.length}`)

    if (!htmlContent.value) {
        logDebug('没有HTML内容，取消创建视图')
        return
    }

    const container = document.getElementById('action-view-container')
    if (!container) {
        logError('找不到容器元素: action-view-container')
        return
    }

    // 清空容器
    logDebug('清空视图容器')
    container.innerHTML = ''

    // 创建iframe以沙箱方式渲染HTML内容
    logDebug('创建iframe沙箱')
    const iframe = document.createElement('iframe')
    iframe.id = 'action-view-iframe'
    iframe.style.width = '100%'
    iframe.style.height = '100%'
    iframe.style.border = 'none'
    iframe.sandbox.add('allow-scripts', 'allow-same-origin')

    // 添加到容器
    container.appendChild(iframe)

    // 写入HTML内容
    const doc = iframe.contentDocument || iframe.contentWindow?.document
    if (doc) {
        logDebug('向iframe写入HTML内容')
        doc.open()
        doc.write(htmlContent.value)
        doc.close()

        // 添加通信API
        if (iframe.contentWindow) {
            logDebug('已创建iframe，准备添加通信API')
            // TODO: 可以在这里添加插件视图和主应用之间的通信API
        }

        logInfo('视图已成功渲染')
    } else {
        logError('无法获取iframe文档对象')
    }
}

// 监听动作变化
watch(() => props.action, (newAction, oldAction) => {
    logDebug(`动作变化: ${oldAction?.id || 'null'} -> ${newAction?.id || 'null'}`)

    if (newAction) {
        if (useWebContentsView.value) {
            // 使用WebContentsView
            if (newAction.viewPath) {
                createWebContentsView(newAction)
            }
        } else {
            // 使用iframe
            loadViewContent()
        }
    } else if (currentViewId.value) {
        // 如果动作被清除，销毁当前视图
        window.electron.plugins.views.destroy(currentViewId.value)
        currentViewId.value = null
    }
}, { immediate: true })

// 监听HTML内容变化 (仅用于iframe方式)
watch(htmlContent, (newContent, oldContent) => {
    if (!useWebContentsView.value && newContent) {
        logDebug(`HTML内容变化: 旧=${oldContent.length}字节, 新=${newContent.length}字节`)
        createIframeView()
    }
})

// 组件挂载时初始化
onMounted(() => {
    logInfo('ActionView组件已挂载')

    if (props.action && props.action.viewPath) {
        if (useWebContentsView.value) {
            createWebContentsView(props.action)
        } else {
            loadViewContent()
        }
    }
})

// 组件卸载时清理
onUnmounted(() => {
    logInfo('ActionView组件将卸载，清理资源')

    // 清理WebContentsView
    if (currentViewId.value) {
        logDebug(`销毁视图: ${currentViewId.value}`)
        window.electron.plugins.views.destroy(currentViewId.value)
        currentViewId.value = null
    }

    // 清理iframe容器
    const container = document.getElementById('action-view-container')
    if (container) {
        container.innerHTML = ''
    }
})

// 公开组件属性
defineExpose({
    currentViewId
})

const hide = () => {
    if (currentViewId.value) {
        window.electron.plugins.views.hide(currentViewId.value)
        currentViewId.value = null
    }
}

const toggleDevTools = () => {
    if (currentViewId.value) {
        window.electron.plugins.views.toggleDevTools(currentViewId.value)
    }
}
</script>

<template>
    <div class="action-view">
        <div class="action-view-toolbar">
            <button class="close-btn" @click="hide">
                <svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 24 24">
                    <path fill="currentColor" d="M18 6L6 18M6 6l12 12" stroke="currentColor" stroke-width="2"
                        stroke-linecap="round" stroke-linejoin="round" />
                </svg>
            </button>
            <button class="devtools-btn" @click="toggleDevTools" title="切换开发者工具">
                <svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 24 24">
                    <path fill="currentColor" d="m6.327 20.7l-2.543-2.4l8.903-8.9l-8.903-8.9L6.327.1l11.446 11.3z" />
                </svg>
            </button>
        </div>
        <!-- 加载中 -->
        <div v-if="loading" class="h-full flex items-center justify-center">
            <div class="text-center">
                <span class="loading loading-spinner loading-lg"></span>
                <div class="mt-4">加载视图内容...</div>
            </div>
        </div>

        <!-- 错误信息 -->
        <div v-else-if="error" class="h-full flex items-center justify-center">
            <div class="text-center text-error">
                <div class="text-3xl mb-2">
                    <i class="i-mdi-alert-circle-outline"></i>
                </div>
                <div>{{ error }}</div>
                <button @click="loadViewContent" class="btn btn-sm btn-outline btn-error mt-4">重试</button>
            </div>
        </div>

        <!-- 无动作 -->
        <div v-else-if="!action" class="h-full flex items-center justify-center text-center opacity-50">
            <div>
                <div class="text-5xl mb-4">
                    <i class="i-mdi-view-dashboard-outline"></i>
                </div>
                <div>请选择一个动作来查看其视图</div>
            </div>
        </div>

        <!-- 无视图 -->
        <div v-else-if="!action.viewPath" class="h-full flex items-center justify-center text-center opacity-50">
            <div>
                <div class="text-5xl mb-4">
                    <i class="i-mdi-view-dashboard-off-outline"></i>
                </div>
                <div>该动作没有自定义视图</div>
            </div>
        </div>

        <!-- 视图容器 (仅用于iframe方式) -->
        <div v-else-if="!useWebContentsView" id="action-view-container" class="h-full"></div>

        <!-- WebContentsView方式不需要容器，视图直接由主进程管理 -->
        <div v-else-if="useWebContentsView && currentViewId" class="plugin-view-container">
            <!-- 这里是空的，因为WebContentsView由主进程管理并展示 -->
        </div>
    </div>
</template>

<style scoped>
.action-view {
    position: relative;
    height: 100%;
    width: 100%;
}

.action-view-toolbar {
    position: absolute;
    top: 0;
    right: 0;
    z-index: 100;
    display: flex;
    padding: 4px;
}

.close-btn,
.devtools-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 24px;
    height: 24px;
    background: rgba(0, 0, 0, 0.5);
    border: none;
    border-radius: 4px;
    color: white;
    cursor: pointer;
    margin-left: 4px;
}

.close-btn:hover,
.devtools-btn:hover {
    background: rgba(0, 0, 0, 0.7);
}

.plugin-view-container {
    height: 100%;
    min-height: 300px;
    position: relative;
}
</style>
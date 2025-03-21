<script setup lang="ts">
import { ref, watch, onMounted, onUnmounted } from 'vue'
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

// 加载视图内容
const loadViewContent = async () => {
    logDebug(`loadViewContent被调用，当前动作: ${props.action?.id || 'null'}`)

    if (!props.action || !props.action.viewPath) {
        logDebug('无动作或动作没有视图路径，清空内容')
        htmlContent.value = ''
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

// 创建Web视图
const createView = () => {
    logDebug(`createView被调用，HTML内容长度: ${htmlContent.value.length}`)

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
    loadViewContent()
}, { immediate: true })

// 监听HTML内容变化
watch(htmlContent, (newContent, oldContent) => {
    logDebug(`HTML内容变化: 旧=${oldContent.length}字节, 新=${newContent.length}字节`)
    if (newContent) {
        createView()
    }
})

// 组件挂载时初始化
onMounted(() => {
    logInfo('ActionView组件已挂载')
    loadViewContent()
})

// 组件卸载时清理
onUnmounted(() => {
    logInfo('ActionView组件将卸载，清理资源')
    const container = document.getElementById('action-view-container')
    if (container) {
        container.innerHTML = ''
    }
})
</script>

<template>
    <div class="action-view h-full">
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

        <!-- 视图容器 -->
        <div v-else id="action-view-container" class="h-full"></div>
    </div>
</template>
/**
* 插件动作视图
*
* 功能：
* 1. 展示选中的插件动作详情
* 2. 显示动作执行结果或自定义视图
* 3. 提供返回到动作列表的功能
*/
<script setup lang="ts">
import { ref, inject, watch } from 'vue'
import type { PluginManagerAPI, PluginAction } from '@renderer/components/PluginManager.vue'

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
// 动作视图的HTML内容
const actionViewHtml = ref('')
// 是否正在加载动作视图
const isLoading = ref(false)
// 动作执行的结果
const actionResult = ref<any>(null)
// 是否发生错误
const hasError = ref(false)
// 错误信息
const errorMessage = ref('')

// 加载并执行动作
const loadAndExecuteAction = async () => {
    if (!pluginManager) return

    const actionId = props.actionId
    isLoading.value = true
    hasError.value = false
    errorMessage.value = ''

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

        // 如果有视图路径，加载视图HTML
        if (action.viewPath) {
            await pluginManager.loadActionView(actionId)
            actionViewHtml.value = pluginManager.actionViewHtml
            console.log(`PluginView: 加载视图HTML完成，长度: ${actionViewHtml.value.length}`)
        } else {
            actionViewHtml.value = ''
        }
    } catch (error) {
        const errorMsg = error instanceof Error ? error.message : String(error)
        console.error(`PluginView: 执行动作失败: ${errorMsg}`)
        hasError.value = true
        errorMessage.value = errorMsg
        actionViewHtml.value = ''
    } finally {
        isLoading.value = false
    }
}

// 返回动作列表
const goBack = () => {
    emit('back')
}

// 在动作ID变化时重新加载
watch(() => props.actionId, (newId) => {
    if (newId) {
        loadAndExecuteAction()
    }
}, { immediate: true })

// 当从插件管理器更新视图HTML时
watch(() => pluginManager?.actionViewHtml, (newHtml) => {
    if (newHtml) {
        actionViewHtml.value = newHtml
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

        <!-- 动作视图内容 -->
        <div v-else-if="actionViewHtml" class="flex-1 border rounded-lg p-4 bg-white shadow-sm overflow-auto">
            <div v-html="actionViewHtml"></div>
        </div>

        <!-- 显示结果（如果没有视图） -->
        <div v-else-if="actionResult && !actionViewHtml" class="flex-1 p-4 border rounded-lg bg-gray-50 overflow-auto">
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
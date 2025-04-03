<!--
 * DevView.vue - 开发测试视图
 * 
 * 用于测试各种功能：
 * - IPC通信测试
 * - 错误处理测试
 * - 流式数据测试
 -->
<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'

const electronApi = window.electron
const devApi = electronApi.dev

// 测试数据
const echoInput = ref('')
const echoResult = ref('')
const errorResult = ref('')
const streamResult = ref('')

// 清除函数集合
const cleanupFunctions: (() => void)[] = []

// 回显测试
const testEcho = async () => {
    try {
        const result = await devApi.echo(echoInput.value)
        echoResult.value = JSON.stringify(result, null, 2)
    } catch (error) {
        echoResult.value = `错误: ${error}`
    }
}

// 错误测试
const testError = async (shouldError: boolean) => {
    try {
        const result = await devApi.testError(shouldError)
        errorResult.value = JSON.stringify(result, null, 2)
    } catch (error) {
        errorResult.value = `错误: ${error}`
    }
}

// 流式数据测试
const testStream = async () => {
    try {
        streamResult.value = ''
        const result = await devApi.testStream()
        console.log('流式测试开始，ID:', result)
    } catch (error) {
        streamResult.value = `错误: ${error}`
    }
}

onMounted(() => {
    // 设置流数据监听器
    const removeChunkListener = devApi.onStreamChunk((_, response) => {
        if (response.success) {
            streamResult.value += response.data
        } else {
            streamResult.value += `\n错误: ${response.error}`
        }
    })

    const removeDoneListener = devApi.onStreamDone(() => {
        streamResult.value += '\n[完成]'
    })

    // 保存清除函数
    cleanupFunctions.push(removeChunkListener, removeDoneListener)
})

onUnmounted(() => {
    // 清理所有监听器
    cleanupFunctions.forEach(cleanup => cleanup())
})
</script>

<template>
    <div class="w-full h-full flex flex-col overflow-hidden p-4">
        <h2 class="text-2xl font-bold mb-4">开发测试</h2>

        <!-- 回显测试 -->
        <div class="mb-6">
            <h3 class="text-lg font-semibold mb-2">回显测试</h3>
            <div class="flex gap-2 mb-2">
                <input v-model="echoInput" type="text" placeholder="输入测试内容"
                    class="input input-bordered flex-1" />
                <button @click="testEcho" class="btn btn-primary">测试</button>
            </div>
            <pre class="bg-base-200 p-2 rounded-lg" v-if="echoResult">{{ echoResult }}</pre>
        </div>

        <!-- 错误处理测试 -->
        <div class="mb-6">
            <h3 class="text-lg font-semibold mb-2">错误处理测试</h3>
            <div class="flex gap-2 mb-2">
                <button @click="() => testError(false)" class="btn btn-success">正常测试</button>
                <button @click="() => testError(true)" class="btn btn-error">错误测试</button>
            </div>
            <pre class="bg-base-200 p-2 rounded-lg" v-if="errorResult">{{ errorResult }}</pre>
        </div>

        <!-- 流式数据测试 -->
        <div class="mb-6">
            <h3 class="text-lg font-semibold mb-2">流式数据测试</h3>
            <div class="flex gap-2 mb-2">
                <button @click="testStream" class="btn btn-primary">开始流式测试</button>
            </div>
            <pre class="bg-base-200 p-2 rounded-lg" v-if="streamResult">{{ streamResult }}</pre>
        </div>
    </div>
</template> 
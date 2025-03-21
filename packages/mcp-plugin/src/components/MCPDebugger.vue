<template>
    <div class="flex flex-col h-full">
        <h2 class="text-2xl font-bold mb-4">MCP 调试工具</h2>

        <!-- 配置区域 -->
        <MCPConfig v-model:scriptPath="config.scriptPath" v-model:startupCommands="config.startupCommands"
            :isRunning="isRunning" @start="startMCPService" @stop="stopMCPService" @save-config="saveConfig"
            @load-config="loadConfig" />

        <!-- 状态栏 -->
        <div class="my-2 px-3 py-2 rounded-lg" :class="statusBarClass">
            <span class="font-medium">{{ statusMessage }}</span>
        </div>

        <!-- 控制台输出和交互区域 -->
        <div class="flex-1 flex flex-col gap-4 overflow-hidden">
            <!-- 控制台输出 -->
            <MCPConsole ref="consoleRef" :logs="logs" @clear="clearLogs" />

            <!-- 命令输入 -->
            <MCPInteraction :command="currentCommand" :isRunning="isRunning" :commandHistory="commandHistory"
                @update:command="currentCommand = $event" @send="sendCommand" @load-history="loadHistoryCommand" />
        </div>
    </div>
</template>

<script lang="ts" setup>
// 引入Vue核心API
import { ref, reactive, computed, onMounted } from 'vue'

// 引入子组件
import MCPConfig from './MCPConfig.vue'
import MCPConsole from './MCPConsole.vue'
import MCPInteraction from './MCPInteraction.vue'

// 声明window.api类型
declare global {
    interface Window {
        api: {
            mcp: {
                start: () => Promise<{ success: boolean; message: string }>
                stop: () => Promise<{ success: boolean; message: string }>
                sendCommand: (command: string) => Promise<{ success: boolean; response: string }>
                saveConfig: (config: { scriptPath: string; startupCommands: string[] }) => Promise<{ success: boolean; message: string }>
                getConfig: () => Promise<{ scriptPath: string; startupCommands: string[] }>
            }
        }
    }
}

// 配置
const config = reactive({
    scriptPath: '',
    startupCommands: [] as string[]
})

// 状态
const isRunning = ref(false)
const logs = ref<{ text: string, type: 'info' | 'error' | 'command' | 'system' }[]>([])
const currentCommand = ref('')
const commandHistory = ref<string[]>([])
const error = ref<string | null>(null)
const consoleRef = ref<{ scrollToBottom: () => void } | null>(null)

// 计算状态栏样式和消息
const statusBarClass = computed(() => {
    if (error.value) return 'bg-error/20 text-error'
    if (isRunning.value) return 'bg-success/20 text-success'
    return 'bg-base-200 text-base-content'
})

const statusMessage = computed(() => {
    if (error.value) return `错误: ${error.value}`
    if (isRunning.value) return '服务运行中'
    return '服务已停止'
})

// 组件挂载时加载配置
onMounted(async () => {
    try {
        const savedConfig = await window.api.mcp.getConfig()
        if (savedConfig) {
            config.scriptPath = savedConfig.scriptPath
            config.startupCommands = savedConfig.startupCommands
            addLog('已加载保存的配置', 'system')
        }
    } catch (err) {
        console.error('加载配置失败:', err)
    }
})

// 添加日志
const addLog = (text: string, type: 'info' | 'error' | 'command' | 'system' = 'info'): void => {
    logs.value.push({ text, type })
    // 自动滚动到底部
    setTimeout(() => {
        if (consoleRef.value) {
            consoleRef.value.scrollToBottom()
        }
    }, 50)
}

// 清除日志
const clearLogs = (): void => {
    logs.value = []
}

// 启动MCP服务
const startMCPService = async (): Promise<void> => {
    if (isRunning.value) return

    try {
        error.value = null

        addLog('🚀 正在启动 MCP 服务...', 'system')
        addLog(`📂 脚本路径：${config.scriptPath}`, 'system')
        addLog(`🧰 启动命令：${config.startupCommands.join(', ') || '无'}`, 'system')

        // 使用IPC调用启动MCP服务
        const result = await window.api.mcp.start()

        if (result.success) {
            isRunning.value = true
            addLog('✅ MCP 服务启动成功', 'system')
        } else {
            throw new Error(result.message)
        }
    } catch (err: unknown) {
        const errorMessage = err instanceof Error ? err.message : String(err)
        error.value = errorMessage
        addLog(`❌ MCP 服务启动失败：${error.value}`, 'error')
        isRunning.value = false
    }
}

// 停止MCP服务
const stopMCPService = async (): Promise<void> => {
    if (!isRunning.value) return

    try {
        // 使用IPC调用停止MCP服务
        const result = await window.api.mcp.stop()

        if (result.success) {
            addLog('⏹️ MCP 服务已停止', 'system')
            isRunning.value = false
            error.value = null
        } else {
            throw new Error(result.message)
        }
    } catch (err: unknown) {
        const errorMessage = err instanceof Error ? err.message : String(err)
        error.value = errorMessage
        addLog(`❌ MCP 服务停止失败：${error.value}`, 'error')
    }
}

// 发送命令
const sendCommand = async (): Promise<void> => {
    if (!isRunning.value || !currentCommand.value.trim()) return

    const command = currentCommand.value.trim()
    addLog(`> ${command}`, 'command')

    // 添加到历史
    commandHistory.value.unshift(command)
    if (commandHistory.value.length > 20) {
        commandHistory.value.pop()
    }

    try {
        // 使用IPC调用发送命令到MCP服务
        const result = await window.api.mcp.sendCommand(command)

        if (result.success) {
            addLog(result.response, 'info')
        } else {
            throw new Error(result.response)
        }
    } catch (err: unknown) {
        const errorMessage = err instanceof Error ? err.message : String(err)
        addLog(`命令执行错误: ${errorMessage}`, 'error')
    }

    currentCommand.value = ''
}

// 加载历史命令
const loadHistoryCommand = (command: string): void => {
    currentCommand.value = command
}

// 保存配置
const saveConfig = async (): Promise<void> => {
    try {
        // 使用IPC调用保存配置
        const result = await window.api.mcp.saveConfig({
            scriptPath: config.scriptPath,
            startupCommands: config.startupCommands
        })

        if (result.success) {
            addLog('已保存配置', 'system')
        } else {
            throw new Error(result.message)
        }
    } catch (err: unknown) {
        const errorMessage = err instanceof Error ? err.message : String(err)
        addLog(`保存配置失败: ${errorMessage}`, 'error')
    }
}

// 加载配置
const loadConfig = async (): Promise<void> => {
    try {
        // 使用IPC调用加载配置
        const savedConfig = await window.api.mcp.getConfig()

        if (savedConfig) {
            config.scriptPath = savedConfig.scriptPath
            config.startupCommands = savedConfig.startupCommands
            addLog('已加载配置', 'system')
        } else {
            addLog('没有找到保存的配置', 'system')
        }
    } catch (err: unknown) {
        const errorMessage = err instanceof Error ? err.message : String(err)
        addLog(`加载配置失败: ${errorMessage}`, 'error')
    }
}
</script>
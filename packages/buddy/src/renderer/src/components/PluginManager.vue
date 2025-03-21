<script setup lang="ts">
import { ref, onMounted, provide } from 'vue'

// 定义插件动作类型
export interface PluginAction {
    id: string
    title: string
    description: string
    icon: string
    plugin: string
}

// 插件管理器接口
export interface PluginManagerAPI {
    actions: PluginAction[]
    loadActions: () => Promise<void>
    executeAction: (actionId: string) => Promise<any>
}

// 存储从主进程获取的插件动作数据
const pluginActions = ref<PluginAction[]>([])

// 加载插件动作
const loadPluginActions = async (): Promise<void> => {
    try {
        // 使用预加载脚本中的send/receive模式
        window.electron.send('get-plugin-actions')

        // 等待回复
        const result = await new Promise<unknown>((resolve) => {
            // 这里我们不保存返回的清理函数，因为我们只处理一次回复就移除监听
            window.electron.receive('get-plugin-actions-reply', (data) => {
                window.electron.removeListener('get-plugin-actions-reply', () => { });
                resolve(data)
            })

            // 5秒后自动移除监听
            setTimeout(() => {
                window.electron.removeListener('get-plugin-actions-reply', () => { });
                resolve([])
            }, 5000)
        })

        // 处理结果
        if (Array.isArray(result)) {
            pluginActions.value = result as PluginAction[]
        }
    } catch (error) {
        console.error('获取插件数据失败:', error)
        pluginActions.value = []
    }
}

// 执行插件动作
const executePluginAction = async (actionId: string): Promise<any> => {
    try {
        // 发送请求
        window.electron.send('execute-plugin-action', actionId)

        // 等待回复
        return await new Promise<any>((resolve, reject) => {
            // 接收回复
            window.electron.receive('execute-plugin-action-reply', (data) => {
                window.electron.removeListener('execute-plugin-action-reply', () => { });
                resolve(data)
            })

            // 5秒后超时
            setTimeout(() => {
                window.electron.removeListener('execute-plugin-action-reply', () => { });
                reject(new Error('执行插件动作超时'))
            }, 5000)
        })
    } catch (error) {
        console.error(`执行插件动作失败: ${error}`)
        throw error
    }
}

// 初始化时加载插件动作
onMounted(() => {
    loadPluginActions()
})

// 提供给子组件的API
const pluginManagerAPI: PluginManagerAPI = {
    actions: pluginActions.value,
    loadActions: loadPluginActions,
    executeAction: executePluginAction
}

// 使用Vue的依赖注入，提供API给子组件
provide('pluginManager', pluginManagerAPI)

// 暴露API给父组件
defineExpose({
    pluginActions,
    loadPluginActions,
    executeAction: executePluginAction,
})
</script>

<template>
    <!-- 插件管理器是一个逻辑组件，不渲染UI -->
    <slot></slot>
</template>
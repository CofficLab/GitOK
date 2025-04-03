<!--
 * ChatView.vue
 * AI聊天界面，使用Vercel AI SDK管理聊天状态和组件
 * 充分利用SDK提供的功能
-->
<script setup lang="ts">
import { ref, onMounted, computed, onUnmounted, watch } from 'vue'
import { useChat } from '@ai-sdk/vue'
import ChatMessage from '../components/ChatMessage.vue'
import { ipcApi } from '../api/ipc-api'
import type { ChatMessage as IChatMessage } from '@/types/api-message'
import type { IpcResponse } from '@/types/ipc-response'
import { logger } from '../utils/logger'

// 预设消息提示
const messageTemplates = [
    { text: '你好，能帮我解答一个问题吗？', color: 'bg-blue-100' },
    { text: '请提供一个JavaScript代码示例', color: 'bg-green-100' },
    { text: '如何使用Vue3的组合式API？', color: 'bg-purple-100' },
    { text: '生成一个简单的markdown列表', color: 'bg-yellow-100' },
]

// 存储活跃请求ID和控制器
const activeRequestId = ref<string | null>(null)
// 存储流式响应数据
const streamBuffer = ref<string>('')
// 存储数据处理函数
let chunkHandler: (() => void) | null = null
let doneHandler: (() => void) | null = null
// 解析器控制器
let streamController: ReadableStreamDefaultController | null = null

// 自定义fetch函数，使用IPC与主进程通信
const customFetch = async (_url: RequestInfo | URL, init?: RequestInit): Promise<Response> => {
    // 从请求中获取消息
    const options = init || {} as RequestInit
    const body = JSON.parse(options.body as string || '{}')
    const apiMessages = body.messages || []

    // logger.info('useChat发送的消息:', apiMessages)

    // 转换为AIManager所需的格式
    const chatMessages: IChatMessage[] = apiMessages.map((msg: any) => ({
        role: msg.role,
        content: msg.content
    }))

    try {
        // 清空缓冲区
        streamBuffer.value = ''

        // 创建新的流
        const stream = new ReadableStream({
            start(controller) {
                streamController = controller

                // 注册数据块处理器
                chunkHandler = ipcApi.onAiChatStreamChunk((response) => {
                    if (!response.success) {
                        controller.error(new Error(response.error || '未知错误'))
                        return
                    }

                    if (response.data) {
                        // 添加到缓冲区
                        streamBuffer.value += response.data
                        logger.debug(`收到数据块: ${response.data.length} 字符`)

                        // 构建SSE格式数据 - 确保 content 字段包含实际内容
                        const data = JSON.stringify({
                            id: crypto.randomUUID(),
                            object: 'chat.completion.chunk',
                            created: Math.floor(Date.now() / 1000),
                            model: 'electron-ai-model',
                            choices: [
                                {
                                    index: 0,
                                    delta: {
                                        content: response.data
                                    },
                                    finish_reason: null
                                }
                            ]
                        })

                        // 发送数据，确保换行格式正确
                        const chunk = `data: ${data}\n\n`
                        logger.debug(`发送SSE数据: ${chunk.length} 字符`)
                        controller.enqueue(new TextEncoder().encode(chunk))
                    }
                })

                // 注册完成处理器
                doneHandler = ipcApi.onAiChatStreamDone((response) => {
                    logger.debug(`收到流式传输完成信号，请求ID: ${response.requestId}`);
                    logger.debug(`当前缓冲区内容长度: ${streamBuffer.value.length} 字符`);

                    try {
                        // 发送完成标记
                        const doneData = JSON.stringify({
                            id: crypto.randomUUID(),
                            object: 'chat.completion.chunk',
                            created: Math.floor(Date.now() / 1000),
                            model: 'electron-ai-model',
                            choices: [
                                {
                                    index: 0,
                                    delta: {},
                                    finish_reason: 'stop'
                                }
                            ]
                        })
                        logger.debug('发送完成标记');
                        controller.enqueue(new TextEncoder().encode(`data: ${doneData}\n\n`))
                        controller.enqueue(new TextEncoder().encode('data: [DONE]\n\n'))

                        // 必须调用 close 来结束流
                        logger.debug('关闭流控制器');
                        controller.close()

                        // 延迟执行，确保所有数据都被处理
                        setTimeout(() => {
                            // 检测消息更新情况
                            if (messages.value.length > 0) {
                                const lastMessage = messages.value[messages.value.length - 1];
                                logger.debug(`流程结束检测：最后消息角色 ${lastMessage.role}, 内容长度 ${lastMessage.content.length}`);

                                // 如果缓冲区有内容但消息没有更新，手动更新
                                if (streamBuffer.value &&
                                    (lastMessage.role !== 'assistant' ||
                                        !lastMessage.content.includes(streamBuffer.value.substring(0, 20)))) {
                                    logger.info('流程结束后手动更新消息');
                                    updateMessagesManually();
                                }
                            }
                        }, 500); // 等待500毫秒
                    } catch (error) {
                        logger.error('发送完成标记时出错:', error);
                    }
                })
            },
            cancel() {
                // 取消请求
                if (activeRequestId.value) {
                    ipcApi.aiChatCancel(activeRequestId.value, "CustomFetch")
                    activeRequestId.value = null
                }

                // 清理处理器
                if (chunkHandler) chunkHandler()
                if (doneHandler) doneHandler()
            }
        })

        // 启动流式聊天
        const response = await ipcApi.aiChatStreamStart(chatMessages)
        if (typeof response === 'string') {
            // 存储请求ID，用于后续可能的取消
            activeRequestId.value = response
        } else if (typeof response === 'object' && response !== null && 'success' in response) {
            const ipcResponse = response as IpcResponse<string>
            if (!ipcResponse.success) {
                throw new Error(ipcResponse.error || '未知错误')
            }
            // 如果返回的是请求ID
            if (typeof ipcResponse.data === 'string') {
                activeRequestId.value = ipcResponse.data
            }
        }

        // 返回可读流响应
        return new Response(stream, {
            headers: {
                'Content-Type': 'text/event-stream; charset=utf-8',
                'Cache-Control': 'no-cache',
                'Connection': 'keep-alive'
            }
        })
    } catch (error) {
        logger.error('AI聊天请求失败:', error)
        activeRequestId.value = null
        throw error
    }
}

// 使用useChat钩子管理聊天状态
const {
    messages,
    input,
    handleSubmit,
    isLoading,
    stop,
    reload,
    setMessages
} = useChat({
    id: 'ai-chat-' + Date.now(),
    initialMessages: [
        {
            id: '1',
            role: 'assistant',
            content: '你好！我是AI助手，很高兴为您服务。有什么我可以帮助你的吗？'
        }
    ],
    api: '/api/chat', // 虚拟API端点
    fetch: customFetch,
    sendExtraMessageFields: true,
    // 添加完成回调，用于调试
    onFinish: (message) => {
        logger.info('对话完成:', message.content.substring(0, 100))
        // 确保消息滚动到底部
        setTimeout(scrollToBottom, 100)
    },
    // 添加消息更新监听
    onResponse: (response) => {
        logger.info('收到响应:', response.status)
        // 确保消息滚动到底部
        setTimeout(scrollToBottom, 100)
    }
})

// 对消息的变化进行监听以便调试
watch(messages, (newMessages) => {
    logger.info('消息更新，当前消息数:', newMessages.length)
    if (newMessages.length > 0) {
        const lastMsg = newMessages[newMessages.length - 1]
        logger.info('最新消息:', lastMsg.role, lastMsg.content.substring(0, 30))
    }
    // 确保消息滚动到底部
    setTimeout(scrollToBottom, 100)
}, { deep: true })

// 消息自动滚动到底部
const messagesContainer = ref<HTMLDivElement | null>(null)

const scrollToBottom = () => {
    if (messagesContainer.value) {
        messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight
    }
}

// 处理预设消息提示的点击
const handleTemplateClick = (text: string) => {
    input.value = text
}

// 处理重新生成
const handleRegenerate = () => {
    reload()
}

// 清空对话
const clearChat = () => {
    setMessages([{
        id: '1',
        role: 'assistant',
        content: '你好！我是AI助手，很高兴为您服务。有什么我可以帮助你的吗？'
    }])
}

// 手动停止生成
const stopGeneration = () => {
    // 取消活跃的请求
    if (activeRequestId.value) {
        ipcApi.aiChatCancel(activeRequestId.value, "ChatView 手动停止")
        activeRequestId.value = null
    }

    // 调用 useChat 的停止函数
    stop()
}

// 判断是否应该显示重新生成按钮
const showRegenerate = computed(() => {
    return !isLoading &&
        messages.value.length > 1 &&
        messages.value[messages.value.length - 1].role === 'assistant'
})

// 手动更新消息（用于调试和紧急情况）
const updateMessagesManually = () => {
    // 如果有缓冲区内容但消息没有更新
    if (streamBuffer.value && messages.value.length > 0) {
        const lastMessageIndex = messages.value.length - 1
        const lastMessage = messages.value[lastMessageIndex]

        // 如果最后一条消息是助手的回复但内容为空，则更新它
        if (lastMessage.role === 'assistant' && !lastMessage.content.trim()) {
            logger.info('手动更新消息内容')
            const updatedMessages = [...messages.value]
            updatedMessages[lastMessageIndex] = {
                ...lastMessage,
                content: streamBuffer.value
            }
            setMessages(updatedMessages)
        }
        // 如果最后一条消息是用户的，添加一条助手的回复
        else if (lastMessage.role === 'user') {
            logger.info('手动添加助手回复消息')
            const newMessage = {
                id: crypto.randomUUID(),
                role: 'assistant' as const,
                content: streamBuffer.value
            }
            setMessages([...messages.value, newMessage])
        }

        // 清空缓冲区
        streamBuffer.value = ''
    }
}

// 添加右键菜单处理
const handleContextMenu = (event: MouseEvent, type: string = 'text') => {
    // 阻止默认的上下文菜单
    event.preventDefault();

    // 检查是否有选中的文本
    const hasSelection = !!window.getSelection()?.toString();

    // 显示自定义上下文菜单
    window.electron.contextMenu.showContextMenu(type, hasSelection);
}

// 复制代码块处理函数
const handleCopyCode = () => {
    const selectedElement = document.querySelector('.chat-bubble pre.hljs.selected');
    if (selectedElement) {
        // 复制代码块内容
        const codeText = selectedElement.textContent || '';
        navigator.clipboard.writeText(codeText)
            .then(() => {
                // 可以添加复制成功的提示
                console.log('代码已复制到剪贴板');
            })
            .catch(err => {
                console.error('复制失败:', err);
            });
    }
}

// 监听复制代码块事件
let copyCodeUnsubscribe: (() => void) | null = null;

onMounted(() => {
    scrollToBottom();

    // 注册复制代码块监听
    copyCodeUnsubscribe = window.electron.contextMenu.onCopyCode(() => {
        handleCopyCode();
    });

    // 为代码块添加选中样式的事件处理
    document.addEventListener('mousedown', handleCodeBlockClick);
});

onUnmounted(() => {
    // 取消活跃的请求
    if (activeRequestId.value) {
        ipcApi.aiChatCancel(activeRequestId.value, "ChatView 组件卸载")
        activeRequestId.value = null
    }

    // 清理处理器
    if (chunkHandler) chunkHandler()
    if (doneHandler) doneHandler()

    // 取消复制代码块监听
    if (copyCodeUnsubscribe) copyCodeUnsubscribe();

    // 移除代码块点击事件监听
    document.removeEventListener('mousedown', handleCodeBlockClick);
});

// 处理代码块点击，添加选中样式
const handleCodeBlockClick = (event: MouseEvent) => {
    // 清除之前的选中状态
    document.querySelectorAll('.chat-bubble pre.hljs.selected').forEach(el => {
        el.classList.remove('selected');
    });

    // 检查点击是否在代码块上
    let target = event.target as HTMLElement;
    while (target && !target.matches('pre.hljs') && target !== document.body) {
        target = target.parentElement as HTMLElement;
    }

    // 如果点击在代码块上，添加选中样式
    if (target && target.matches('pre.hljs')) {
        target.classList.add('selected');
    }
}
</script>

<template>
    <div class="flex flex-col h-full overflow-hidden">
        <!-- 聊天头部 -->
        <div class="p-4 border-b border-base-300 flex justify-between items-center">
            <h1 class="text-xl font-bold">AI 助手</h1>
            <div class="flex items-center gap-2">
                <button @click="clearChat" class="btn btn-sm btn-ghost">
                    清空对话
                </button>
            </div>
        </div>

        <!-- 聊天消息区域 -->
        <div ref="messagesContainer" class="flex-1 overflow-y-auto p-4 space-y-4"
            @contextmenu="handleContextMenu($event, 'text')">
            <ChatMessage v-for="message in messages" :key="message.id" :message="message"
                @contextmenu.stop="handleContextMenu($event, 'chat-message')" />

            <!-- 加载中提示 -->
            <div v-if="isLoading" class="p-3 rounded-lg bg-base-200 mr-auto flex items-center space-x-2 mb-4">
                <div class="loading loading-dots loading-sm"></div>
                <span>AI正在思考...</span>
            </div>

            <!-- 控制按钮 -->
            <div class="flex justify-center gap-2 mt-2 mb-4">
                <button v-if="isLoading" @click="stopGeneration" class="btn btn-sm btn-outline">
                    停止生成
                </button>

                <button v-if="showRegenerate" @click="handleRegenerate" class="btn btn-sm btn-outline">
                    重新生成
                </button>

                <!-- 调试按钮，只在有缓冲区内容且未显示在消息中时显示 -->
                <button
                    v-if="streamBuffer && (!messages || !messages.length || messages[messages.length - 1].role !== 'assistant' || !messages[messages.length - 1].content.includes(streamBuffer.substring(0, 20)))"
                    @click="updateMessagesManually" class="btn btn-sm btn-outline btn-warning">
                    手动更新消息
                </button>
            </div>
        </div>

        <!-- 输入区域 -->
        <div class="p-4 border-t border-base-300">
            <!-- 预设消息提示 -->
            <div class="flex gap-2 mb-3 overflow-x-auto pb-2">
                <button v-for="(template, index) in messageTemplates" :key="index"
                    @click="handleTemplateClick(template.text)" class="btn btn-sm btn-ghost whitespace-nowrap"
                    :class="template.color">
                    {{ template.text }}
                </button>
            </div>

            <!-- 聊天输入 -->
            <form @submit.prevent="handleSubmit()" class="flex items-center">
                <input v-model="input" type="text" placeholder="发送消息..." class="input input-bordered flex-1 mr-2"
                    :disabled="isLoading" @contextmenu="handleContextMenu($event, 'text')" />

                <button type="submit" class="btn btn-primary" :disabled="isLoading || !input.trim()">
                    发送
                </button>
            </form>
        </div>
    </div>
</template>
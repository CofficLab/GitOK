<!--
 * ChatView.vue
 * AI聊天界面，使用Vercel AI SDK管理聊天状态和组件
 * 充分利用SDK提供的功能
-->
<script setup lang="ts">
import { ref, onMounted, watch, computed } from 'vue'
import { useChat } from '@ai-sdk/vue'
import ChatMessage from '../components/ChatMessage.vue'

// 预设消息提示
const messageTemplates = [
    { text: '你好，能帮我解答一个问题吗？', color: 'bg-blue-100' },
    { text: '请提供一个JavaScript代码示例', color: 'bg-green-100' },
    { text: '如何使用Vue3的组合式API？', color: 'bg-purple-100' },
    { text: '生成一个简单的markdown列表', color: 'bg-yellow-100' },
]

// 自定义fetch函数，用于模拟AI响应
const customFetch = async (url: RequestInfo | URL, init?: RequestInit): Promise<Response> => {
    // 从请求中获取消息
    const options = init || {} as RequestInit
    const body = JSON.parse(options.body as string || '{}')
    const apiMessages = body.messages || []

    if (apiMessages.length === 0) {
        return new Response('我是AI助手，很高兴为您服务。')
    }

    const lastMessage = apiMessages[apiMessages.length - 1]
    let response = '我是AI助手，很高兴为您服务。'

    if (lastMessage.role !== 'user') {
        return new Response(response)
    }

    if (lastMessage.content.includes('你好') || lastMessage.content.includes('hello')) {
        response = '你好！我是AI助手，很高兴为您服务。有什么我可以帮助你的吗？'
    } else if (lastMessage.content.includes('天气')) {
        response = '我无法获取实时天气信息，因为我是一个模拟数据的AI助手。如果连接了真实API，我将能够为您提供准确的天气信息。'
    } else if (lastMessage.content.includes('帮助') || lastMessage.content.includes('help')) {
        response = '我可以回答问题、提供信息或与您聊天。请告诉我您需要什么帮助。'
    } else if (lastMessage.content.includes('代码') || lastMessage.content.includes('JavaScript')) {
        response = '以下是一个简单的JavaScript函数示例：\n\n```javascript\nfunction sayHello(name) {\n  return `Hello, ${name}!`;\n}\n\nconsole.log(sayHello("世界"));\n```\n\n您可以复制这段代码并尝试运行它。'
    } else if (lastMessage.content.includes('Vue') || lastMessage.content.includes('组合式API')) {
        response = '在Vue 3中使用组合式API的基本示例：\n\n```js\n// 创建组件\nimport { ref, computed, onMounted } from \'vue\'\n\n// 响应式状态\nconst count = ref(0)\n\n// 计算属性\nconst doubleCount = computed(() => count.value * 2)\n\n// 生命周期钩子\nonMounted(() => {\n  console.log(\'组件已挂载\')\n})\n\n// 方法\nfunction increment() {\n  count.value++\n}\n```\n\n这样就可以在模板中使用这些状态和方法，比如按钮点击和数据显示。'
    } else if (lastMessage.content.includes('列表') || lastMessage.content.includes('markdown')) {
        response = '以下是一个简单的Markdown列表：\n\n## 待办事项清单\n\n* 完成项目文档\n* 修复已知Bug\n* 实现新功能\n\n## 开发步骤\n\n1. 分析需求\n2. 设计架构\n3. 编写代码\n4. 测试功能\n5. 部署上线'
    } else if (lastMessage.content.includes('AI SDK') || lastMessage.content.includes('Vercel')) {
        response = '@ai-sdk/vue 提供了多种有用的功能和钩子：\n\n1. `useChat` - 管理聊天UI状态和流式响应\n2. `useCompletion` - 处理单轮文本补全\n3. `useAssistant` - 与OpenAI Assistant API集成\n\n这些组件使构建AI聊天界面变得简单。'
    }

    // 模拟流式响应
    const encoder = new TextEncoder()
    const chunks = response.split(' ')

    const stream = new ReadableStream({
        async start(controller) {
            for (const chunk of chunks) {
                const bytes = encoder.encode(chunk + ' ')
                controller.enqueue(bytes)
                // 模拟打字效果
                await new Promise(resolve => setTimeout(resolve, 70))
            }
            controller.close()
        }
    })

    return new Response(stream, {
        headers: {
            'Content-Type': 'text/plain; charset=utf-8'
        }
    })
}

// 使用useChat钩子管理聊天状态
const {
    messages,
    input,
    handleSubmit,
    isLoading,
    reload,
    error,
    stop,
    append
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
    fetch: customFetch, // 使用我们自定义的fetch实现
    sendExtraMessageFields: true
})

// 消息自动滚动到底部
const messagesContainer = ref<HTMLDivElement | null>(null)

const scrollToBottom = () => {
    if (messagesContainer.value) {
        messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight
    }
}

onMounted(() => {
    scrollToBottom()
})

// 监听消息变化，自动滚动到底部
watch(messages, () => {
    setTimeout(scrollToBottom, 100)
})

// 处理预设消息提示的点击
const handleTemplateClick = (text: string) => {
    input.value = text
}

// 处理重新生成
const handleRegenerate = () => {
    if (messages.value.length > 1) {
        // 只保留到用户的最后一条消息
        const lastUserMessageIndex = [...messages.value].reverse().findIndex(m => m.role === 'user')
        if (lastUserMessageIndex !== -1) {
            const userIndex = messages.value.length - 1 - lastUserMessageIndex

            // 由于类型限制，我们不使用reload的options.body参数
            // 而是先移除上一个回答，然后重新提交用户最后一个问题
            if (messages.value.length > userIndex + 1) {
                // 移除所有用户最后一个问题之后的消息
                while (messages.value.length > userIndex + 1) {
                    messages.value.pop()
                }

                // 重新提交用户的最后一个问题
                const lastUserMessage = messages.value[userIndex]
                if (lastUserMessage.role === 'user') {
                    append({
                        role: 'user',
                        content: lastUserMessage.content
                    })
                }
            }
        }
    }
}

// 清空对话
const clearChat = () => {
    // 重置为初始状态
    while (messages.value.length > 0) {
        messages.value.pop()
    }

    // 添加初始欢迎消息
    append({
        role: 'assistant',
        content: '你好！我是AI助手，很高兴为您服务。有什么我可以帮助你的吗？'
    })
}

// 判断是否应该显示重新生成按钮
const showRegenerate = computed(() => {
    return !isLoading.value &&
        messages.value.length > 1 &&
        messages.value[messages.value.length - 1].role === 'assistant'
})
</script>

<template>
    <div class="flex flex-col h-full overflow-hidden bg-base-100">
        <!-- 聊天头部 -->
        <div class="p-4 border-b border-base-300 flex justify-between items-center">
            <h1 class="text-xl font-bold">AI 助手</h1>
            <button @click="clearChat" class="btn btn-sm btn-ghost">
                清空对话
            </button>
        </div>

        <!-- 聊天消息区域 -->
        <div ref="messagesContainer" class="flex-1 overflow-y-auto p-4 space-y-4">
            <ChatMessage v-for="message in messages" :key="message.id" :message="message" />

            <!-- 加载中提示 -->
            <div v-if="isLoading" class="p-3 rounded-lg bg-base-200 mr-auto flex items-center space-x-2 mb-4">
                <div class="loading loading-dots loading-sm"></div>
                <span>AI正在思考...</span>
            </div>

            <!-- 错误提示 -->
            <div v-if="error" class="p-3 rounded-lg bg-error text-error-content mr-auto mb-4">
                <p>发生错误: {{ error.message }}</p>
            </div>

            <!-- 控制按钮 -->
            <div class="flex justify-center gap-2 mt-2 mb-4">
                <button v-if="isLoading" @click="stop" class="btn btn-sm btn-outline">
                    停止生成
                </button>

                <button v-if="showRegenerate" @click="handleRegenerate" class="btn btn-sm btn-outline">
                    重新生成
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
            <form @submit.prevent="handleSubmit" class="flex items-center">
                <input v-model="input" type="text" placeholder="发送消息..." class="input input-bordered flex-1 mr-2"
                    :disabled="isLoading" />
                <button type="submit" class="btn btn-primary" :disabled="isLoading || !input.trim()">
                    发送
                </button>
            </form>
        </div>
    </div>
</template>

<style scoped>
/* 确保聊天界面占满可用空间 */
.h-full {
    height: 100%;
}
</style>
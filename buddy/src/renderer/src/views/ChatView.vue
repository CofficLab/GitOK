<!--
ChatView.vue - 聊天视图组件

这个组件负责显示AI聊天界面：
- 显示聊天消息列表
- 提供消息输入框
- 处理消息发送和接收
-->

<script setup lang="ts">
import { ref } from 'vue'

// 聊天消息类型
interface ChatMessage {
    id: string
    content: string
    isUser: boolean
    timestamp: Date
}

// 聊天消息列表
const messages = ref<ChatMessage[]>([])
const messageInput = ref('')

// 发送消息
const sendMessage = () => {
    if (!messageInput.value.trim()) return

    // 添加用户消息
    messages.value.push({
        id: Date.now().toString(),
        content: messageInput.value,
        isUser: true,
        timestamp: new Date()
    })

    // TODO: 在这里添加与AI的通信逻辑

    // 清空输入框
    messageInput.value = ''
}
</script>

<template>
    <div class="w-full h-full flex flex-col">
        <!-- 消息列表 -->
        <div class="flex-1 overflow-y-auto p-4 space-y-4">
            <div v-for="message in messages" :key="message.id" :class="[
                'max-w-[80%] p-3 rounded-lg',
                message.isUser ? 'ml-auto bg-primary text-primary-content' : 'bg-base-200'
            ]">
                {{ message.content }}
            </div>
        </div>

        <!-- 输入区域 -->
        <div class="p-4 border-t border-base-300">
            <div class="flex gap-2">
                <input v-model="messageInput" type="text" placeholder="输入消息..." class="input input-bordered flex-1"
                    @keyup.enter="sendMessage" />
                <button class="btn btn-primary" @click="sendMessage">
                    发送
                </button>
            </div>
        </div>
    </div>
</template>
<!--
 * ChatMessage.vue
 * 聊天消息组件
 * 支持用户消息和AI助手消息的显示
 * 使用 daisyui 和 tailwindcss 样式
-->
<script setup lang="ts">
import { computed } from 'vue'
import type { Message } from '@ai-sdk/vue'

// 定义组件属性
const props = defineProps<{
    message: Message
}>()

// 计算消息的样式类
const messageClass = computed(() => {
    switch (props.message.role) {
        case 'assistant':
            return 'bg-base-200'
        case 'user':
            return 'bg-primary/10'
        case 'system':
            return 'bg-secondary/10'
        default:
            return 'bg-error/10' // 用于错误消息
    }
})

// 计算头像文本
const avatarText = computed(() => {
    switch (props.message.role) {
        case 'assistant':
            return 'AI'
        case 'user':
            return '我'
        case 'system':
            return '系统'
        default:
            return '!'
    }
})

// 计算头像样式
const avatarClass = computed(() => {
    switch (props.message.role) {
        case 'assistant':
            return 'bg-primary text-primary-content'
        case 'user':
            return 'bg-secondary text-secondary-content'
        case 'system':
            return 'bg-accent text-accent-content'
        default:
            return 'bg-error text-error-content'
    }
})
</script>

<template>
    <div class="chat" :class="props.message.role === 'user' ? 'chat-end' : 'chat-start'">
        <!-- 头像 -->
        <div class="chat-image avatar placeholder">
            <div class="w-8 h-8 rounded-full flex items-center justify-center" :class="avatarClass">
                <span class="text-xs font-medium">{{ avatarText }}</span>
            </div>
        </div>

        <!-- 消息内容 -->
        <div class="chat-bubble prose max-w-none" :class="messageClass">
            <!-- 使用 v-html 来支持 markdown 渲染的结果 -->
            <div class="[&>pre]:bg-base-300 [&>pre]:p-4 [&>pre]:rounded-lg [&>pre]:my-2 [&>pre]:overflow-x-auto
                       [&>pre.selected]:ring-2 [&>pre.selected]:ring-primary [&>pre.selected]:ring-opacity-70
                       [&>code]:bg-base-300 [&>code]:px-1 [&>code]:rounded
                       [&>a]:text-primary [&>a]:hover:underline
                       [&>ul]:list-disc [&>ul]:pl-4 [&>ul]:my-2
                       [&>ol]:list-decimal [&>ol]:pl-4 [&>ol]:my-2
                       [&>table]:table [&>table]:table-compact [&>table]:w-full [&>table]:my-2
                       [&>blockquote]:border-l-4 [&>blockquote]:border-base-300 [&>blockquote]:pl-4 [&>blockquote]:my-2"
                v-html="props.message.content">
            </div>
        </div>

        <!-- 消息时间 -->
        <div v-if="props.message.createdAt" class="chat-footer opacity-50 text-xs">
            {{ new Date(props.message.createdAt).toLocaleTimeString() }}
        </div>
    </div>
</template>

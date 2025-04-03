<!--
 * ChatMessage.vue
 * 聊天消息组件，支持Markdown渲染和代码高亮
 * 用于展示用户消息和AI回复
-->
<script setup lang="ts">
import { computed } from 'vue'
import { marked } from 'marked'
import hljs from 'highlight.js'

// 定义props
interface Props {
    message: {
        id: string
        role: 'user' | 'assistant' | 'system' | 'data'
        content: string
    }
}

const props = defineProps<Props>()

// 判断是否是AI消息
const isAI = computed(() => props.message.role === 'assistant' || props.message.role === 'system')

// 渲染Markdown内容（仅对AI消息）
const renderedContent = computed(() => {
    if (!isAI.value) {
        return props.message.content
    }

    // 使用基本的标记解析，不配置高亮以避免类型错误
    try {
        return marked.parse(props.message.content)
    } catch (e) {
        console.error('Markdown解析错误:', e)
        return props.message.content
    }
})
</script>

<template>
    <div :class="[
        'chat-message p-3 rounded-lg max-w-[85%]',
        isAI
            ? 'bg-base-200 mr-auto'
            : 'bg-primary text-primary-content ml-auto'
    ]">
        <!-- 用户消息直接显示文本 -->
        <template v-if="!isAI">
            <p class="whitespace-pre-wrap">{{ message.content }}</p>
        </template>

        <!-- AI消息支持Markdown渲染 -->
        <template v-else>
            <div class="prose prose-sm max-w-none" v-html="renderedContent"></div>
        </template>
    </div>
</template>

<style scoped>
/* 自定义样式 */
.chat-message {
    word-break: break-word;
    transition: all 0.3s ease;
}

/* 让代码块样式美观 */
:deep(pre) {
    padding: 0.75rem;
    border-radius: 0.375rem;
    overflow-x: auto;
    background-color: hsl(var(--n) / 0.1);
}

:deep(code) {
    font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
    font-size: 0.875em;
    padding: 0.2em 0.4em;
    border-radius: 0.25em;
    background-color: hsl(var(--n) / 0.1);
}

:deep(pre code) {
    padding: 0;
    background: none;
}
</style>
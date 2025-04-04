<!--
 * ChatView.vue
 * AI聊天界面，使用Vercel AI SDK管理聊天状态和组件
 * 充分利用SDK提供的功能
-->
<script setup lang="ts">
import { ChatMessage, StreamChunkResponse } from '@/types/api-ai';
import { aiApi } from '@renderer/api/ai-api';
import { ref } from 'vue';

const message = ref('');
const messages: ChatMessage[] = [];

aiApi.onAiChatStreamChunk((response: StreamChunkResponse) => {
    console.log(response);
})
aiApi.send(messages);

function sendMessage() {
    messages.push({
        role: 'user',
        content: message.value
    });
    message.value = '';
    aiApi.send(messages);
}
</script>

<template>
    <input type="text" v-model="message" />
    <button @click="sendMessage">Send</button>
</template>
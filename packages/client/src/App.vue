<template>
  <div class="min-h-screen bg-base-200 flex flex-col">
    <!-- 未配置API密钥时显示提示 -->
    <div v-if="!hasApiKey" class="hero min-h-screen">
      <div class="hero-content text-center">
        <div class="max-w-md">
          <h1 class="text-3xl font-bold">配置需要完成</h1>
          <p class="py-6">请配置您的 <span class="font-bold capitalize">{{ currentProvider }}</span> API 密钥以开始使用AI聊天功能。</p>

          <div class="form-control w-full max-w-xs mx-auto mb-4">
            <label class="label">
              <span class="label-text">选择AI供应商</span>
            </label>
            <select v-model="currentProvider" class="select select-bordered w-full">
              <option value="openai">OpenAI</option>
              <option value="anthropic">Anthropic (Claude)</option>
              <option value="deepseek">DeepSeek</option>
            </select>
          </div>

          <button @click="openSettings" class="btn btn-primary">配置 API 密钥</button>
        </div>
      </div>
    </div>

    <!-- 已配置API密钥显示聊天界面 -->
    <div v-else class="flex flex-col h-screen">
      <!-- 头部 -->
      <div class="navbar bg-base-300">
        <div class="flex-1">
          <a class="btn btn-ghost normal-case text-xl">AI Chat Assistant</a>
        </div>
        <div class="flex-none">
          <div class="dropdown dropdown-end">
            <label tabindex="0" class="btn btn-ghost">
              <span class="capitalize">{{ getProviderName(currentProvider) }}</span>
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 ml-1" fill="none" viewBox="0 0 24 24"
                stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
              </svg>
            </label>
            <ul tabindex="0" class="dropdown-content menu p-2 shadow bg-base-100 rounded-box w-52">
              <li><a @click="changeProvider('openai')" :class="{ 'font-bold': currentProvider === 'openai' }">OpenAI</a>
              </li>
              <li><a @click="changeProvider('anthropic')"
                  :class="{ 'font-bold': currentProvider === 'anthropic' }">Anthropic (Claude)</a></li>
              <li><a @click="changeProvider('deepseek')"
                  :class="{ 'font-bold': currentProvider === 'deepseek' }">DeepSeek</a></li>
              <li>
                <hr class="my-1" />
              </li>
              <li><a @click="openSettings" class="flex items-center gap-2">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24"
                    stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                      d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                      d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                  </svg>
                  设置
                </a></li>
            </ul>
          </div>
        </div>
      </div>

      <!-- 消息区域 -->
      <div class="flex-1 overflow-auto p-4 bg-base-200" ref="messagesContainer">
        <div class="flex flex-col gap-3">
          <div v-for="(message, index) in messages" :key="index"
            :class="['chat', message.role === 'user' ? 'chat-end' : 'chat-start']">
            <div class="chat-image avatar">
              <div class="w-10 rounded-full">
                <img v-if="message.role === 'user'" src="https://api.dicebear.com/6.x/bottts/svg?seed=user"
                  alt="User" />
                <img v-else :src="`https://api.dicebear.com/6.x/bottts/svg?seed=${currentProvider}`"
                  :alt="currentProvider" />
              </div>
            </div>
            <div :class="['chat-bubble', message.role === 'user' ? 'chat-bubble-primary' : 'chat-bubble-secondary']">
              {{ message.content }}
            </div>
            <div class="chat-footer opacity-50">
              {{ message.role === 'user' ? '您' : getProviderName(currentProvider) }}
            </div>
          </div>

          <div v-if="isLoading" class="chat chat-start">
            <div class="chat-image avatar">
              <div class="w-10 rounded-full">
                <img :src="`https://api.dicebear.com/6.x/bottts/svg?seed=${currentProvider}`" :alt="currentProvider" />
              </div>
            </div>
            <div class="chat-bubble chat-bubble-secondary">
              <span class="loading loading-dots loading-md"></span>
            </div>
          </div>
        </div>
      </div>

      <!-- 输入区域 -->
      <div class="p-4 bg-base-300">
        <div class="join w-full">
          <textarea v-model="inputMessage" class="textarea textarea-bordered join-item w-full focus:outline-none"
            placeholder="输入消息..." @keydown.enter.prevent="sendMessage" :disabled="isLoading"></textarea>
          <button class="btn btn-primary join-item" @click="sendMessage" :disabled="isLoading || !inputMessage.trim()">
            <svg v-if="!isLoading" xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24"
              stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
            </svg>
            <span v-else class="loading loading-spinner"></span>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
interface Message {
  role: 'user' | 'assistant';
  content: string;
}

// 确保vscode对象在全局可用
declare const vscode: {
  postMessage: (message: any) => void;
};

export default {
  name: 'App',
  data() {
    return {
      // AI配置
      currentProvider: 'openai',
      hasApiKey: false,

      // 聊天状态
      messages: [] as Message[],
      inputMessage: '',
      isLoading: false
    };
  },
  mounted() {
    // 监听来自扩展的消息
    window.addEventListener('message', this.handleExtensionMessage);
  },
  beforeUnmount() {
    // 移除监听器
    window.removeEventListener('message', this.handleExtensionMessage);
  },
  methods: {
    getProviderName(provider: string): string {
      const nameMap: Record<string, string> = {
        'openai': 'OpenAI',
        'anthropic': 'Claude',
        'deepseek': 'DeepSeek'
      };
      return nameMap[provider] || provider;
    },

    changeProvider(provider: string) {
      this.currentProvider = provider;
      // 检查新提供商是否已配置
      vscode.postMessage({
        command: 'checkProvider',
        provider
      });
      // 清空聊天记录
      this.messages = [];
    },

    handleExtensionMessage(event: MessageEvent) {
      const message = event.data;

      switch (message.command) {
        case 'setConfig':
          this.currentProvider = message.aiProvider;
          this.hasApiKey = message.hasApiKey;
          break;

        case 'configurationRequired':
          this.hasApiKey = false;
          this.currentProvider = message.provider;
          break;

        case 'providerStatus':
          this.hasApiKey = message.hasApiKey;
          if (!message.hasApiKey) {
            // 如果新提供商未配置，提示用户
            this.messages.push({
              role: 'assistant',
              content: `请先配置 ${this.getProviderName(this.currentProvider)} API 密钥`
            });
          }
          break;

        case 'aiResponse':
          this.isLoading = false;
          this.messages.push({
            role: 'assistant',
            content: message.response
          });
          this.scrollToBottom();
          break;

        case 'error':
          this.isLoading = false;
          this.messages.push({
            role: 'assistant',
            content: `错误: ${message.message}`
          });
          this.scrollToBottom();
          break;
      }
    },

    sendMessage() {
      if (!this.inputMessage.trim() || this.isLoading) return;

      // 添加用户消息
      this.messages.push({
        role: 'user',
        content: this.inputMessage
      });

      // 发送消息到扩展
      vscode.postMessage({
        command: 'fetchAIResponse',
        prompt: this.inputMessage,
        provider: this.currentProvider
      });

      // 清空输入并显示加载状态
      this.inputMessage = '';
      this.isLoading = true;
      this.scrollToBottom();
    },

    openSettings() {
      vscode.postMessage({
        command: 'openSettings',
        provider: this.currentProvider
      });
    },

    scrollToBottom() {
      // 滚动到底部
      this.$nextTick(() => {
        if (this.$refs.messagesContainer) {
          const container = this.$refs.messagesContainer as HTMLElement;
          container.scrollTop = container.scrollHeight;
        }
      });
    }
  }
};
</script>

<style>
/* 全局样式保留，因为DaisyUI和Tailwind会处理大部分样式 */
.textarea {
  height: 60px;
  resize: none;
  font-family: inherit;
}
</style>
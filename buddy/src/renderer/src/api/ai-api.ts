import type { ChatMessage, AIModelConfig, StreamChunkResponse, StreamDoneResponse } from '@/types/api-ai';

const ai = window.electron.ai;

export const aiApi = {
  // AI 相关功能
  async aiChat(messages: ChatMessage[]): Promise<string> {
    return await ai.aiChat(messages);
  },

  // 流式传输相关功能
  async aiChatStreamStart(messages: ChatMessage[]): Promise<string> {
    return await ai.aiChatStreamStart(messages);
  },

  onAiChatStreamChunk(callback: (response: StreamChunkResponse) => void): () => void {
    return ai.onAiChatStreamChunk(callback);
  },

  onAiChatStreamDone(callback: (response: StreamDoneResponse) => void): () => void {
    return ai.onAiChatStreamDone(callback);
  },

  async aiChatCancel(requestId: string, reason: string): Promise<boolean> {
    return await ai.aiChatCancel(requestId, reason);
  },

  // 配置相关功能
  async aiGetConfig(): Promise<AIModelConfig> {
    return await ai.aiGetConfig();
  },

  async aiSetConfig(config: Partial<AIModelConfig>): Promise<AIModelConfig> {
    return await ai.aiSetConfig(config);
  }
};
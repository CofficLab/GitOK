import type { ChatMessage, AIModelConfig, StreamChunkResponse, StreamDoneResponse } from '@/types/api-message';

const electronApi = window.electron;
const ipc = electronApi.ipc;

export const ipcApi = {
  async openFolder(folder: string): Promise<string> {
    return await ipc.openFolder(folder);
  },

  // AI 相关功能
  async aiChat(messages: ChatMessage[]): Promise<string> {
    return await ipc.aiChat(messages);
  },

  // 流式传输相关功能
  async aiChatStreamStart(messages: ChatMessage[]): Promise<string> {
    return await ipc.aiChatStreamStart(messages);
  },

  onAiChatStreamChunk(callback: (response: StreamChunkResponse) => void): () => void {
    return ipc.onAiChatStreamChunk(callback);
  },

  onAiChatStreamDone(callback: (response: StreamDoneResponse) => void): () => void {
    return ipc.onAiChatStreamDone(callback);
  },

  async aiChatCancel(requestId: string, reason: string): Promise<boolean> {
    return await ipc.aiChatCancel(requestId, reason);
  },

  // 配置相关功能
  async aiGetConfig(): Promise<AIModelConfig> {
    return await ipc.aiGetConfig();
  },

  async aiSetConfig(config: Partial<AIModelConfig>): Promise<AIModelConfig> {
    return await ipc.aiSetConfig(config);
  }
};
import type { AiApi, ChatMessage, StreamChunkResponse, StreamDoneResponse } from '@coffic/buddy-types';

const ai = window.electron.ai;

export const aiIpc: AiApi = {
  async send(messages: ChatMessage[]): Promise<string> {
    return await ai.send(messages);
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
};
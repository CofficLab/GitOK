/**
 * 基础 IPC 通信模块
 * 提供基本的进程间通信功能
 */
import { ipcRenderer } from 'electron';
import { IpcApi, ChatMessage, StreamChunkResponse, StreamDoneResponse } from '@/types/api-message';
import { IPC_METHODS } from '@/types/ipc-methods';

export const ipcApi: IpcApi = {
  send: (channel: string, ...args: unknown[]): void => {
    ipcRenderer.send(channel, ...args);
  },
  receive: (channel: string, callback: (...args: unknown[]) => void): void => {
    ipcRenderer.on(channel, (_, ...args) => callback(...args));
  },
  removeListener: (
    channel: string,
    callback: (...args: unknown[]) => void
  ): void => {
    ipcRenderer.removeListener(channel, callback);
  },

  openFolder: async (directory: string): Promise<string> => {
    let response = ipcRenderer.invoke(IPC_METHODS.OPEN_FOLDER, directory);

    return response;
  },

  // AI聊天功能
  aiChat: async (messages: ChatMessage[]): Promise<string> => {
    return ipcRenderer.invoke(IPC_METHODS.AI_CHAT, messages);
  },

  // 启动流式AI聊天会话
  aiChatStreamStart: async (messages: ChatMessage[]): Promise<string> => {
    return ipcRenderer.invoke(IPC_METHODS.AI_CHAT_STREAM_START, messages);
  },

  // 注册流式聊天数据块监听器
  onAiChatStreamChunk: (callback: (response: StreamChunkResponse) => void): (() => void) => {
    const handler = (_: any, response: StreamChunkResponse) => callback(response);
    ipcRenderer.on(IPC_METHODS.AI_CHAT_STREAM_CHUNK, handler);

    // 返回取消注册函数
    return () => {
      ipcRenderer.removeListener(IPC_METHODS.AI_CHAT_STREAM_CHUNK, handler);
    };
  },

  // 注册流式聊天完成监听器
  onAiChatStreamDone: (callback: (response: StreamDoneResponse) => void): (() => void) => {
    const handler = (_: any, response: StreamDoneResponse) => callback(response);
    ipcRenderer.on(IPC_METHODS.AI_CHAT_STREAM_DONE, handler);

    // 返回取消注册函数
    return () => {
      ipcRenderer.removeListener(IPC_METHODS.AI_CHAT_STREAM_DONE, handler);
    };
  },

  // 取消AI聊天请求
  aiChatCancel: async (requestId: string): Promise<boolean> => {
    return ipcRenderer.invoke(IPC_METHODS.AI_CHAT_CANCEL, requestId);
  },

  // 获取AI配置
  aiGetConfig: async () => {
    return ipcRenderer.invoke(IPC_METHODS.AI_GET_CONFIG);
  },

  // 设置AI配置
  aiSetConfig: async (config: any) => {
    return ipcRenderer.invoke(IPC_METHODS.AI_SET_CONFIG, config);
  },
};

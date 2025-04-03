/**
 * 基础 IPC 通信模块的类型定义
 * 提供基本的进程间通信功能的接口
 */

// 聊天消息类型
export interface ChatMessage {
  role: 'user' | 'assistant' | 'system';
  content: string;
}

// AI模型配置类型
export interface AIModelConfig {
  type: string;
  modelName: string;
  apiKey?: string;
  system?: string;
  temperature?: number;
  maxTokens?: number;
}

// 流式响应类型
export interface StreamChunkResponse {
  success: boolean;
  data?: string;
  error?: string;
  requestId: string;
}

// 流式完成响应类型
export interface StreamDoneResponse {
  success: boolean;
  requestId: string;
}

export interface IpcApi {
  /**
   * 向主进程发送消息
   * @param channel 通信频道名称
   * @param args 要发送的参数
   */
  send: (channel: string, ...args: unknown[]) => void;

  /**
   * 接收来自主进程的消息
   * @param channel 通信频道名称
   * @param callback 接收到消息时的回调函数
   */
  receive: (channel: string, callback: (...args: unknown[]) => void) => void;

  /**
   * 移除消息监听器
   * @param channel 通信频道名称
   * @param callback 要移除的回调函数
   */
  removeListener: (
    channel: string,
    callback: (...args: unknown[]) => void
  ) => void;

  /**
   * 打开文件夹
   * @param directory 要打开的目录路径
   */
  openFolder: (directory: string) => Promise<string>;

  /**
   * 发送AI聊天请求
   * @param messages 聊天消息数组
   * @returns 返回AI助手的响应文本
   */
  aiChat: (messages: ChatMessage[]) => Promise<string>;

  /**
   * 启动流式AI聊天会话
   * @param messages 聊天消息数组
   * @returns 返回请求ID，用于后续操作和取消请求
   */
  aiChatStreamStart: (messages: ChatMessage[]) => Promise<string>;

  /**
   * 注册流式聊天数据块监听器
   * @param callback 接收到数据块时的回调函数
   * @returns 返回取消注册函数
   */
  onAiChatStreamChunk: (callback: (response: StreamChunkResponse) => void) => () => void;

  /**
   * 注册流式聊天完成监听器
   * @param callback 聊天完成时的回调函数
   * @returns 返回取消注册函数
   */
  onAiChatStreamDone: (callback: (response: StreamDoneResponse) => void) => () => void;

  /**
   * 取消AI聊天请求
   * @param requestId 要取消的请求ID
   * @param reason 取消原因
   * @returns 返回是否成功取消
   */
  aiChatCancel: (requestId: string, reason: string) => Promise<boolean>;

  /**
   * 获取AI配置
   * @returns 返回当前AI模型配置
   */
  aiGetConfig: () => Promise<AIModelConfig>;

  /**
   * 设置AI配置
   * @param config AI模型配置参数
   * @returns 返回更新后的AI模型配置
   */
  aiSetConfig: (config: Partial<AIModelConfig>) => Promise<AIModelConfig>;
}

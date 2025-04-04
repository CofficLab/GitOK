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

  // AI API类型
  export interface AiApi {
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
  
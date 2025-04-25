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

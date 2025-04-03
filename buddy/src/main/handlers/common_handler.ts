import { IPC_METHODS } from '@/types/ipc-methods';
import { IpcRoute } from '../provider/RouterService';
import { IpcResponse } from '@/types/ipc-response';
import { shell } from 'electron';
import { logger } from '../managers/LogManager';
import { aiManager, type ChatMessage, type AIModelConfig } from '../managers/AIManager';
import { v4 as uuidv4 } from 'uuid';

/**
 * 基础的IPC路由配置
 */
export const baseRoutes: IpcRoute[] = [
    {
        channel: IPC_METHODS.OPEN_FOLDER,
        handler: (_, directory: string): IpcResponse<string> => {
            logger.debug(`打开: ${directory}`);
            try {
                shell.openPath(directory);
                return { success: true, data: "打开成功" };
            } catch (error) {
                const errorMessage =
                    error instanceof Error ? error.message : String(error);
                return { success: false, error: errorMessage };
            }
        },
    },

    // AI聊天功能 (非流式，保留向后兼容)
    {
        channel: IPC_METHODS.AI_CHAT,
        handler: async (_, messages: ChatMessage[]): Promise<IpcResponse<string>> => {
            logger.debug(`AI聊天请求: ${messages.length}条消息`);
            try {
                const response = await aiManager.sendChatMessage(messages);

                // 读取响应流
                const reader = response.body?.getReader();
                if (!reader) {
                    throw new Error('无法读取响应流');
                }

                let fullResponse = '';
                const decoder = new TextDecoder();
                let buffer = '';

                while (true) {
                    const { done, value } = await reader.read();
                    if (done) break;

                    // 将新的块添加到缓冲区
                    buffer += decoder.decode(value, { stream: true });

                    // 处理完整的 SSE 消息
                    const lines = buffer.split('\n');
                    buffer = lines.pop() || ''; // 保留最后一个不完整的行

                    for (const line of lines) {
                        if (line.startsWith('data: ')) {
                            const data = line.slice(5); // 移除 'data: ' 前缀
                            if (data === '[DONE]') continue;

                            try {
                                const json = JSON.parse(data);
                                const content = json.choices?.[0]?.delta?.content || '';
                                fullResponse += content;
                            } catch (e) {
                                logger.warn('解析SSE消息失败:', e);
                                continue;
                            }
                        }
                    }
                }

                // 处理剩余的缓冲区
                if (buffer) {
                    const data = buffer.replace('data: ', '');
                    if (data && data !== '[DONE]') {
                        try {
                            const json = JSON.parse(data);
                            const content = json.choices?.[0]?.delta?.content || '';
                            fullResponse += content;
                        } catch (e) {
                            logger.warn('解析最后的SSE消息失败:', e);
                        }
                    }
                }

                // 确保解码器正确处理最后的数据
                decoder.decode();

                return { success: true, data: fullResponse };
            } catch (error) {
                logger.error(`AI聊天请求失败:`, error);
                return {
                    success: false,
                    error: error instanceof Error ? error.message : String(error)
                };
            }
        },
    },

    // 启动流式AI聊天会话
    {
        channel: IPC_METHODS.AI_CHAT_STREAM_START,
        handler: async (event, messages: ChatMessage[]): Promise<IpcResponse<string>> => {
            logger.debug(`启动流式AI聊天: ${messages.length}条消息`);
            try {
                const requestId = uuidv4();
                logger.debug(`生成请求ID: ${requestId}`);

                // 异步处理流式响应
                (async () => {
                    try {
                        const response = await aiManager.sendChatMessage(messages, undefined, requestId);
                        const reader = response.body?.getReader();

                        if (!reader) {
                            event.sender.send(IPC_METHODS.AI_CHAT_STREAM_CHUNK, {
                                success: false,
                                error: '无法读取响应流',
                                requestId
                            });
                            return;
                        }

                        const decoder = new TextDecoder();
                        let buffer = '';

                        while (true) {
                            const { done, value } = await reader.read();
                            if (done) break;

                            // 将新的块添加到缓冲区
                            buffer += decoder.decode(value, { stream: true });

                            // 处理并发送完整的 SSE 消息
                            const lines = buffer.split('\n');
                            buffer = lines.pop() || ''; // 保留最后一个不完整的行

                            for (const line of lines) {
                                if (line.startsWith('data: ')) {
                                    const data = line.slice(5); // 移除 'data: ' 前缀
                                    if (data === '[DONE]') {
                                        logger.debug('收到流式传输结束标记 [DONE]');
                                        continue;
                                    }

                                    try {
                                        // 打印原始数据以便调试
                                        logger.debug(`解析SSE数据: ${data.substring(0, 100)}${data.length > 100 ? '...' : ''}`);

                                        const json = JSON.parse(data);

                                        // 处理AIManager直接返回的文本格式（不是JSON格式）
                                        if (typeof json === 'string') {
                                            event.sender.send(IPC_METHODS.AI_CHAT_STREAM_CHUNK, {
                                                success: true,
                                                data: json,
                                                requestId
                                            });
                                            continue;
                                        }

                                        const content = json.choices?.[0]?.delta?.content || '';

                                        if (content) {
                                            event.sender.send(IPC_METHODS.AI_CHAT_STREAM_CHUNK, {
                                                success: true,
                                                data: content,
                                                requestId
                                            });
                                        }
                                    } catch (e) {
                                        // 如果解析JSON失败，尝试直接将数据作为文本发送
                                        if (data && data !== '[DONE]' && !data.startsWith('{') && !data.startsWith('[')) {
                                            logger.info('直接作为文本发送:', data);
                                            event.sender.send(IPC_METHODS.AI_CHAT_STREAM_CHUNK, {
                                                success: true,
                                                data,
                                                requestId
                                            });
                                        } else {
                                            logger.warn('解析SSE消息失败:', e, '数据:', data.substring(0, 50));
                                        }
                                        continue;
                                    }
                                }
                            }
                        }

                        // 处理剩余的缓冲区
                        if (buffer) {
                            // 确保数据格式正确
                            let data = buffer;
                            if (buffer.startsWith('data: ')) {
                                data = buffer.slice(5); // 移除 'data: ' 前缀
                            }

                            if (data && data !== '[DONE]') {
                                // 如果是结束标记，不作处理
                                if (data === '[DONE]') {
                                    logger.debug('缓冲区中收到流式传输结束标记 [DONE]');
                                } else {
                                    try {
                                        // 打印原始数据以便调试
                                        logger.debug(`解析缓冲区剩余数据: ${data.substring(0, 100)}${data.length > 100 ? '...' : ''}`);

                                        // 尝试解析JSON
                                        const json = JSON.parse(data);

                                        // 处理AIManager直接返回的文本格式
                                        if (typeof json === 'string') {
                                            event.sender.send(IPC_METHODS.AI_CHAT_STREAM_CHUNK, {
                                                success: true,
                                                data: json,
                                                requestId
                                            });
                                        } else {
                                            const content = json.choices?.[0]?.delta?.content || '';

                                            if (content) {
                                                event.sender.send(IPC_METHODS.AI_CHAT_STREAM_CHUNK, {
                                                    success: true,
                                                    data: content,
                                                    requestId
                                                });
                                            }
                                        }
                                    } catch (e) {
                                        // 如果解析JSON失败，尝试直接将数据作为文本发送
                                        if (data && !data.startsWith('{') && !data.startsWith('[')) {
                                            logger.info('直接作为文本发送缓冲区数据:', data);
                                            event.sender.send(IPC_METHODS.AI_CHAT_STREAM_CHUNK, {
                                                success: true,
                                                data,
                                                requestId
                                            });
                                        } else {
                                            logger.warn('解析最后的SSE消息失败:', e, '数据:', data.substring(0, 50));
                                        }
                                    }
                                }
                            }
                        }

                        // 发送完成信号
                        event.sender.send(IPC_METHODS.AI_CHAT_STREAM_DONE, {
                            success: true,
                            requestId
                        });
                    } catch (error) {
                        logger.error(`流式AI聊天请求失败:`, error);
                        event.sender.send(IPC_METHODS.AI_CHAT_STREAM_CHUNK, {
                            success: false,
                            error: error instanceof Error ? error.message : String(error),
                            requestId
                        });
                    }
                })();

                // 立即返回请求ID
                return { success: true, data: requestId };
            } catch (error) {
                logger.error(`启动流式AI聊天失败:`, error);
                return {
                    success: false,
                    error: error instanceof Error ? error.message : String(error)
                };
            }
        },
    },

    // 取消AI聊天请求
    {
        channel: IPC_METHODS.AI_CHAT_CANCEL,
        handler: (_, requestId: string): IpcResponse<boolean> => {
            logger.debug(`取消AI聊天请求: ${requestId}`);
            try {
                const cancelled = aiManager.cancelRequest(requestId);
                return { success: true, data: cancelled };
            } catch (error) {
                logger.error(`取消AI聊天请求失败:`, error);
                return {
                    success: false,
                    error: error instanceof Error ? error.message : String(error)
                };
            }
        },
    },

    // 获取AI配置
    {
        channel: IPC_METHODS.AI_GET_CONFIG,
        handler: (): IpcResponse<AIModelConfig> => {
            try {
                const config = aiManager.getDefaultModelConfig();
                return { success: true, data: config };
            } catch (error) {
                const errorMessage =
                    error instanceof Error ? error.message : String(error);
                return { success: false, error: errorMessage };
            }
        },
    },

    // 设置AI配置
    {
        channel: IPC_METHODS.AI_SET_CONFIG,
        handler: (_, config: Partial<AIModelConfig>): IpcResponse<AIModelConfig> => {
            try {
                aiManager.setDefaultModel(config);
                const updatedConfig = aiManager.getDefaultModelConfig();
                return { success: true, data: updatedConfig };
            } catch (error) {
                const errorMessage =
                    error instanceof Error ? error.message : String(error);
                return { success: false, error: errorMessage };
            }
        },
    },

    // 开发测试处理器
    {
        channel: IPC_METHODS.DEV_TEST_ECHO,
        handler: (_, data: any): IpcResponse<any> => {
            logger.debug(`开发测试-回显:`, data);
            return { success: true, data };
        },
    },
    {
        channel: IPC_METHODS.DEV_TEST_ERROR,
        handler: (_, shouldError: boolean): IpcResponse<string> => {
            logger.debug(`开发测试-错误处理: ${shouldError}`);
            if (shouldError) {
                throw new Error('这是一个测试错误');
            }
            return { success: true, data: '错误测试成功' };
        },
    },
    {
        channel: IPC_METHODS.DEV_TEST_STREAM,
        handler: async (event): Promise<IpcResponse<string>> => {
            logger.debug(`开发测试-流处理开始`);
            const requestId = uuidv4();

            // 模拟流式数据
            (async () => {
                try {
                    const messages = ['Hello', 'World', '!', '这是', '流式', '测试'];
                    for (const msg of messages) {
                        await new Promise(resolve => setTimeout(resolve, 500));
                        event.sender.send(IPC_METHODS.AI_CHAT_STREAM_CHUNK, {
                            success: true,
                            data: msg,
                            requestId
                        });
                    }

                    event.sender.send(IPC_METHODS.AI_CHAT_STREAM_DONE, {
                        success: true,
                        requestId
                    });
                } catch (error) {
                    event.sender.send(IPC_METHODS.AI_CHAT_STREAM_CHUNK, {
                        success: false,
                        error: error instanceof Error ? error.message : String(error),
                        requestId
                    });
                }
            })();

            return { success: true, data: requestId };
        },
    },
];

// 导出初始化函数，用于设置监听器
export function setupStreamListeners(): void {
    // 注意：此处不需要unregister，因为这个函数只会被调用一次
    // 如果需要在应用的生命周期内多次调用，需要实现相应的清理函数
}
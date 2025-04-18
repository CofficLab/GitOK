
import { IpcRoute } from '../provider/RouterService.js';
import { logger } from '../managers/LogManager.js';
import { aiManager, type ChatMessage } from '../managers/AIManager.js';
import { v4 as uuidv4 } from 'uuid';
import { IpcResponse, StreamChunkResponse } from '@coffic/buddy-types';
import { IPC_METHODS } from '@/types/ipc-methods.js';
/**
 * AI路由配置
 */
export const aiRoutes: IpcRoute[] = [
    // 启动流式AI聊天会话
    {
        channel: IPC_METHODS.AI_CHAT_SEND,
        handler: async (event, messages: ChatMessage[]): Promise<IpcResponse<string>> => {
            logger.debug(`启动流式AI聊天: ${messages.length}条消息`);
            try {
                const requestId = uuidv4();
                logger.debug(`生成请求ID: ${requestId}`);

                aiManager.sendChatMessage(messages,
                    (chunk: string) => {
                        logger.debug(`聊天数据块: ${chunk}`);
                        event.sender.send(IPC_METHODS.AI_CHAT_STREAM_CHUNK, {
                            success: true,
                            data: chunk,
                            requestId
                        } as StreamChunkResponse);
                    }, () => {
                        logger.debug(`聊天完成`);
                        event.sender.send(IPC_METHODS.AI_CHAT_STREAM_DONE, {
                            success: true,
                            requestId
                        });
                    }, undefined, requestId);

                return {
                    success: true,
                    data: requestId
                };
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
        handler: (_, requestId: string, reason: string): IpcResponse<boolean> => {
            logger.debug(`取消AI聊天请求: ${requestId}，原因是：${reason}`);
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
];
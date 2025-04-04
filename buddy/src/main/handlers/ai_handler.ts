import { IPC_METHODS } from '@/types/ipc-methods';
import { IpcRoute } from '../provider/RouterService';
import { IpcResponse } from '@/types/ipc-response';
import { logger } from '../managers/LogManager';
import { aiManager, type ChatMessage, type AIModelConfig } from '../managers/AIManager';
import { v4 as uuidv4 } from 'uuid';

/**
 * AI路由配置
 */
export const aiRoutes: IpcRoute[] = [
    // 启动流式AI聊天会话
    {
        channel: IPC_METHODS.AI_CHAT_STREAM_START,
        handler: async (event, messages: ChatMessage[]): Promise<IpcResponse<string>> => {
            logger.debug(`启动流式AI聊天: ${messages.length}条消息`);
            try {
                const requestId = uuidv4();
                logger.debug(`生成请求ID: ${requestId}`);

                await aiManager.sendChatMessage(messages,(chunk:string)=>{
                    logger.debug(`聊天数据块: ${chunk}`);
                    event.sender.send(IPC_METHODS.AI_CHAT_STREAM_CHUNK, {
                        success: true,
                        data: chunk,
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
];
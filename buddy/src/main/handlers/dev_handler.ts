import { IPC_METHODS } from '@/types/ipc-methods';
import { IpcRoute } from '../provider/RouterService';
import { IpcResponse } from '@/types/ipc-response';
import { logger } from '../managers/LogManager';
import { v4 as uuidv4 } from 'uuid';

export const devRoutes: IpcRoute[] = [
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
import { IPC_METHODS } from '@/types/ipc-methods';
import { IpcRoute } from '../services/RouterService';
import { IpcResponse } from '@/types/ipc-response';
import { shell } from 'electron';
import { logger } from '../managers/LogManager';

/**
 * 基础的IPC路由配置
 */
export const baseRoutes: IpcRoute[] = [
    {
        channel: IPC_METHODS.OPEN_FOLDER,
        handler: (_, directory: string): IpcResponse<string> => {
            logger.debug(`打开文件夹: ${directory}`);
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
];
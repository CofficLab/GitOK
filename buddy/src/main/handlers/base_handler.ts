import { IPC_METHODS } from '@/types/ipc-methods';
import { IpcRoute } from '../services/RouterService';
import { IpcResponse } from '@/types/ipc-response';
import { shell } from 'electron';

/**
 * 基础的IPC路由配置
 */
export const baseRoutes: IpcRoute[] = [
    {
        channel: IPC_METHODS.OPEN_FOLDER,
        handler: (_, directory: string): IpcResponse<void> => {
            try {
                shell.openPath(directory);
                return { success: true, data: undefined };
            } catch (error) {
                const errorMessage =
                    error instanceof Error ? error.message : String(error);
                return { success: false, error: errorMessage };
            }
        },
    },
];
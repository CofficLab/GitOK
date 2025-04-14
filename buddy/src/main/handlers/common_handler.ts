import { IPC_METHODS } from '@/types/ipc-methods';
import { IpcRoute } from '../provider/RouterService';
import { IpcResponse } from '@/types/ipc-response';
import { shell } from 'electron';
import { logger } from '../managers/LogManager';
import { viewManager } from '../managers/ViewManager';

/**
 * 基础的IPC路由配置
 */
export const baseRoutes: IpcRoute[] = [
    {
        channel: IPC_METHODS.Open_Folder,
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

    {
        channel: IPC_METHODS.Create_View,
        handler: (_, bounds): Promise<unknown> => {
            return viewManager.createView(bounds);
        }
    },

    {
        channel: IPC_METHODS.Destroy_View,
        handler: (_, id): void => {
            return viewManager.destroyView(id);
        }
    },

    {
        channel: IPC_METHODS.Destroy_Plugin_Views,
        handler: (_): void => {
            return viewManager.destroyAllViews();
        }
    }
];

// 导出初始化函数，用于设置监听器
export function setupStreamListeners(): void {
    // 注意：此处不需要unregister，因为这个函数只会被调用一次
    // 如果需要在应用的生命周期内多次调用，需要实现相应的清理函数
}
/**
 * 预加载脚本入口文件
 * 整合所有模块并暴露给渲染进程
 */
import { contextBridge } from 'electron';
import { ipcRenderer } from 'electron';
import { IpcApi, IpcResponse } from '@coffic/buddy-types';
import { logger } from '@/main/managers/LogManager.js';

const verbose = true;

export const ipcApi: IpcApi = {
    send: (channel: string, ...args: unknown[]): void => {
        ipcRenderer.send(channel, ...args);
    },

    receive: (channel: string, callback: (...args: unknown[]) => void): void => {
        if (verbose) {
            logger.info('====== 注册IPC监听器:', channel);
        }

        ipcRenderer.on(channel, (_, ...args) => callback(...args));
    },

    removeListener: (
        channel: string,
        callback: (...args: unknown[]) => void
    ): void => {
        ipcRenderer.removeListener(channel, callback);
    },

    invoke: async (channel: string, ...args: unknown[]): Promise<IpcResponse<any>> => {
        logger.info('调用IPC方法:', channel, '参数是: ', args);

        const response = await ipcRenderer.invoke(channel, ...args);

        try {
            return response as IpcResponse<any>;
        } catch (error: any) {
            throw new Error("IPC通信出错", error)
        }
    },
};

// 使用 contextBridge 暴露 API 到渲染进程
if (process.contextIsolated) {
    try {
        contextBridge.exposeInMainWorld('ipc', ipcApi);
    } catch (error) {
        console.error(error);
    }
} else {
    // @ts-ignore (define in dts)
    window.ipc = ipcApi;
}

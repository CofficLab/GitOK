import { ipcRenderer } from 'electron';
import { IPC_METHODS } from '@/types/ipc-methods';

// 开发测试API
export const devApi = {
    // 回显测试
    echo: async (data: any) => {
        return await ipcRenderer.invoke(IPC_METHODS.DEV_TEST_ECHO, data)
    },
    // 错误处理测试
    testError: async (shouldError: boolean) => {
        return await ipcRenderer.invoke(IPC_METHODS.DEV_TEST_ERROR, shouldError)
    },
    // 流处理测试
    testStream: async () => {
        return await ipcRenderer.invoke(IPC_METHODS.DEV_TEST_STREAM)
    },
    // 监听流数据
    onStreamChunk: (callback: (event: any, response: any) => void) => {
        ipcRenderer.on(IPC_METHODS.AI_CHAT_STREAM_CHUNK, callback)
        return () => {
            ipcRenderer.removeListener(IPC_METHODS.AI_CHAT_STREAM_CHUNK, callback)
        }
    },
    // 监听流结束
    onStreamDone: (callback: (event: any, response: any) => void) => {
        ipcRenderer.on(IPC_METHODS.AI_CHAT_STREAM_DONE, callback)
        return () => {
            ipcRenderer.removeListener(IPC_METHODS.AI_CHAT_STREAM_DONE, callback)
        }
    }
}
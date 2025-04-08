/**
 * 配置管理预加载脚本
 * 
 * 提供配置管理的IPC接口，供渲染进程调用
 */

import { contextBridge, ipcRenderer } from 'electron'
import { IPC_METHODS } from '@/types/ipc-methods'

export interface ConfigAPI {
    /**
     * 获取所有配置
     */
    getAll: () => Promise<any>

    /**
     * 获取指定配置项
     * @param key 配置键，支持点符号访问嵌套属性
     * @param defaultValue 默认值
     */
    get: <T>(key: string, defaultValue?: T) => Promise<T>

    /**
     * 设置配置项
     * @param key 配置键，支持点符号访问嵌套属性
     * @param value 配置值
     */
    set: <T>(key: string, value: T) => Promise<boolean>

    /**
     * 删除配置项
     * @param key 配置键
     */
    delete: (key: string) => Promise<boolean>

    /**
     * 重置所有配置为默认值
     */
    reset: () => Promise<boolean>

    /**
     * 获取配置文件所在的文件夹路径
     */
    getConfigPath: () => Promise<string>
}

// 导出配置API到渲染进程
export const configAPI: ConfigAPI = {
    getAll: () => ipcRenderer.invoke(IPC_METHODS.CONFIG_GET_ALL),
    get: (key, defaultValue) => ipcRenderer.invoke(IPC_METHODS.CONFIG_GET, key, defaultValue),
    set: (key, value) => ipcRenderer.invoke(IPC_METHODS.CONFIG_SET, key, value),
    delete: (key) => ipcRenderer.invoke(IPC_METHODS.CONFIG_DELETE, key),
    reset: () => ipcRenderer.invoke(IPC_METHODS.CONFIG_RESET),
    getConfigPath: () => ipcRenderer.invoke(IPC_METHODS.CONFIG_GET_PATH)
}


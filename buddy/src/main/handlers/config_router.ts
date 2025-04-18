/**
 * 配置相关路由
 * 
 * 负责处理配置相关的IPC请求
 */

import { IpcRoute } from '../provider/RouterService.js'
import { configManager } from '../managers/ConfigManager.js'
import { logger } from '../managers/LogManager.js'
import { IpcResponse } from '@coffic/buddy-types'
import { IPC_METHODS } from '@/types/ipc-methods.js'

export const routes: IpcRoute[] = [
    {
        channel: IPC_METHODS.CONFIG_GET_ALL,
        handler: async () => {
            try {
                return configManager.getAll()
            } catch (error) {
                logger.error('IPC获取所有配置失败:', error)
                throw error
            }
        }
    },
    {
        channel: IPC_METHODS.CONFIG_GET,
        handler: async (_event, key: string, defaultValue?: any) => {
            try {
                return configManager.get(key, defaultValue)
            } catch (error) {
                logger.error(`IPC获取配置[${key}]失败:`, error)
                throw error
            }
        }
    },
    {
        channel: IPC_METHODS.CONFIG_SET,
        handler: async (_event, key: string, value: any) => {
            try {
                configManager.set(key, value)
                return true
            } catch (error) {
                logger.error(`IPC设置配置[${key}]失败:`, error)
                throw error
            }
        }
    },
    {
        channel: IPC_METHODS.CONFIG_DELETE,
        handler: async (_event, key: string) => {
            try {
                configManager.delete(key)
                return true
            } catch (error) {
                logger.error(`IPC删除配置[${key}]失败:`, error)
                throw error
            }
        }
    },
    {
        channel: IPC_METHODS.CONFIG_RESET,
        handler: async () => {
            try {
                configManager.reset()
                return true
            } catch (error) {
                logger.error('IPC重置所有配置失败:', error)
                throw error
            }
        }
    },
    {
        channel: IPC_METHODS.CONFIG_GET_PATH,
        handler: async (): Promise<IpcResponse<string>> => {
            try {
                const path = configManager.getConfigPath()

                return {
                    success: true,
                    data: path
                }
            } catch (error) {
                logger.error('IPC获取配置路径失败:', error)
                return {
                    success: false,
                    error: (error as Error).message
                }
            }
        }
    }
] 
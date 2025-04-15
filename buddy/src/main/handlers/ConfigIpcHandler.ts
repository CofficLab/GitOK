/**
 * 配置IPC处理器
 * 
 * 处理与配置相关的IPC通信
 * 包括读取、写入配置等操作
 */

import { ipcMain } from 'electron'
import { configManager } from '../managers/ConfigManager.js'
import { logger } from '../managers/LogManager.js'
import { IPC_METHODS } from '@coffic/buddy-types'

/**
 * 注册配置相关的IPC处理器
 */
export function registerConfigIpcHandlers(): void {
    logger.info('注册配置IPC处理器')

    // 获取所有配置
    ipcMain.handle(IPC_METHODS.CONFIG_GET_ALL, async () => {
        try {
            return configManager.getAll()
        } catch (error) {
            logger.error('IPC获取所有配置失败:', error)
            throw error
        }
    })

    // 获取特定配置
    ipcMain.handle(IPC_METHODS.CONFIG_GET, async (_, key: string, defaultValue?: any) => {
        try {
            return configManager.get(key, defaultValue)
        } catch (error) {
            logger.error(`IPC获取配置[${key}]失败:`, error)
            throw error
        }
    })

    // 设置配置
    ipcMain.handle(IPC_METHODS.CONFIG_SET, async (_, key: string, value: any) => {
        try {
            configManager.set(key, value)
            return true
        } catch (error) {
            logger.error(`IPC设置配置[${key}]失败:`, error)
            throw error
        }
    })

    // 删除配置
    ipcMain.handle(IPC_METHODS.CONFIG_DELETE, async (_, key: string) => {
        try {
            configManager.delete(key)
            return true
        } catch (error) {
            logger.error(`IPC删除配置[${key}]失败:`, error)
            throw error
        }
    })

    // 重置所有配置
    ipcMain.handle(IPC_METHODS.CONFIG_RESET, async () => {
        try {
            configManager.reset()
            return true
        } catch (error) {
            logger.error('IPC重置所有配置失败:', error)
            throw error
        }
    })
}

/**
 * 注销配置相关的IPC处理器
 */
export function unregisterConfigIpcHandlers(): void {
    logger.info('注销配置IPC处理器')

    ipcMain.removeHandler(IPC_METHODS.CONFIG_GET_ALL)
    ipcMain.removeHandler(IPC_METHODS.CONFIG_GET)
    ipcMain.removeHandler(IPC_METHODS.CONFIG_SET)
    ipcMain.removeHandler(IPC_METHODS.CONFIG_DELETE)
    ipcMain.removeHandler(IPC_METHODS.CONFIG_RESET)
} 
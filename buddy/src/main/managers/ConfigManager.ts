/**
 * 配置管理器
 * 
 * 负责应用配置的存取，基于electron-store
 * 支持读取、保存配置，以及监听配置变化
 */

import { BaseManager } from './BaseManager'
import { app } from 'electron'
import path from 'path'
import { logger } from './LogManager'

const verbose = false

// 动态导入electron-store，解决CommonJS和ESM模块不兼容问题
let ElectronStore: any

// 默认配置
export interface DefaultConfig {
    // 应用基础配置
    app: {
        theme: string
        language: string
        autoLaunch: boolean
        autoUpdate: boolean
    }
    // 快捷键配置
    shortcut: {
        toggle: string
        quit: string
    }
    // AI相关配置
    ai: {
        provider: string
        model: string
        apiHost?: string
        temperature: number
        maxTokens: number
        systemPrompt: string
    }
    // 扩展的自定义配置，可以添加任意键值对
    [key: string]: any
}

// 默认配置值
const DEFAULT_CONFIG: DefaultConfig = {
    app: {
        theme: 'auto', // auto, light, dark
        language: 'zh-CN',
        autoLaunch: true,
        autoUpdate: true
    },
    shortcut: {
        toggle: 'Alt+Space',
        quit: 'Alt+Q'
    },
    ai: {
        provider: 'openai',
        model: 'gpt-3.5-turbo',
        temperature: 0.7,
        maxTokens: 2000,
        systemPrompt: '你是一个有用的AI助手。'
    }
}

class ConfigManager extends BaseManager {
    private static instance: ConfigManager
    private store: any
    private configPath: string = ''

    private constructor() {
        super({
            name: 'ConfigManager',
            enableLogging: true
        })

        this.initStore()
    }

    /**
     * 异步初始化存储
     */
    private async initStore(): Promise<void> {
        try {
            // 动态导入，解决ES模块兼容性问题
            const module = await import('electron-store')
            ElectronStore = module.default

            // 配置存储位置
            const userDataPath = app.getPath('userData')
            this.configPath = userDataPath
            const storePath = path.join(userDataPath, 'config.json')

            // 初始化存储
            this.store = new ElectronStore({
                name: 'config',
                cwd: userDataPath,
                defaults: DEFAULT_CONFIG
            })

            if (verbose) {
                logger.info('配置管理器初始化成功，配置文件位置:', storePath)
            }
        } catch (error) {
            logger.error('配置管理器初始化失败:', error)
            throw this.handleError(error, '配置管理器初始化失败', true)
        }
    }

    /**
     * 获取ConfigManager单例
     */
    public static getInstance(): ConfigManager {
        if (!ConfigManager.instance) {
            ConfigManager.instance = new ConfigManager()
        }
        return ConfigManager.instance
    }

    /**
     * 获取所有配置
     */
    public getAll(): DefaultConfig {
        try {
            return this.store.store
        } catch (error) {
            logger.error('获取所有配置失败:', error)
            throw this.handleError(error, '获取所有配置失败', true)
        }
    }

    /**
     * 获取特定配置项
     * @param key 配置键，支持点符号访问嵌套属性
     * @param defaultValue 默认值
     */
    public get<T>(key: string, defaultValue?: T): T {
        try {
            return this.store.get(key, defaultValue as any) as T
        } catch (error) {
            logger.error(`获取配置[${key}]失败:`, error)
            throw this.handleError(error, `获取配置[${key}]失败`, true)
        }
    }

    /**
     * 设置配置项
     * @param key 配置键，支持点符号访问嵌套属性
     * @param value 配置值
     */
    public set<T>(key: string, value: T): void {
        try {
            this.store.set(key, value)
            logger.info(`设置配置[${key}]成功`)
            this.emit('config-changed', { key, value })
        } catch (error) {
            logger.error(`设置配置[${key}]失败:`, error)
            throw this.handleError(error, `设置配置[${key}]失败`, true)
        }
    }

    /**
     * 检查配置项是否存在
     * @param key 配置键
     */
    public has(key: string): boolean {
        return this.store.has(key)
    }

    /**
     * 删除配置项
     * @param key 配置键
     */
    public delete(key: string): void {
        try {
            this.store.delete(key)
            logger.info(`删除配置[${key}]成功`)
            this.emit('config-deleted', { key })
        } catch (error) {
            logger.error(`删除配置[${key}]失败:`, error)
            throw this.handleError(error, `删除配置[${key}]失败`, true)
        }
    }

    /**
     * 重置所有配置为默认值
     */
    public reset(): void {
        try {
            this.store.clear()
            this.store.set(DEFAULT_CONFIG)
            logger.info('重置所有配置成功')
            this.emit('config-reset')
        } catch (error) {
            logger.error('重置所有配置失败:', error)
            throw this.handleError(error, '重置所有配置失败', true)
        }
    }

    /**
     * 获取配置文件所在的文件夹路径
     * @returns 配置文件夹路径
     */
    public getConfigPath(): string {
        if (!this.configPath) {
            this.configPath = app.getPath('userData')
        }
        return this.configPath
    }

    /**
     * 监听配置变化
     * @param callback 回调函数
     */
    public onDidChange<T>(key: string, callback: (newValue: T, oldValue: T) => void): () => void {
        return this.store.onDidChange(key, callback)
    }

    /**
     * 监听任意配置变化
     * @param callback 回调函数
     */
    public onDidAnyChange(callback: (newValue: Readonly<DefaultConfig> | undefined, oldValue: Readonly<DefaultConfig> | undefined) => void): () => void {
        return this.store.onDidAnyChange(callback)
    }

    /**
     * 清理资源
     */
    public cleanup(): void {
        // electron-store 会自动保存，不需要特别的清理
        this.removeAllListeners()
        logger.info('配置管理器已清理')
    }
}

// 导出单例
export const configManager = ConfigManager.getInstance() 
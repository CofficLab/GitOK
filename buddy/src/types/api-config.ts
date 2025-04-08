/**
 * 配置API类型定义
 */

import { DefaultConfig } from '../main/managers/ConfigManager'

export interface ConfigApi {
    /**
     * 获取所有配置
     */
    getAll: () => Promise<DefaultConfig>

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
} 
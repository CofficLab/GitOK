import { PluginType } from './plugin-type.js';
import { PluginStatus } from './plugin-status.js';

/**
 * 插件信息接口
 */
export interface SendablePlugin {
    /**
     * 插件ID
     */
    id: string;

    /**
     * 插件名称
     */
    name: string;

    /**
     * 插件描述
     */
    description: string;

    /**
     * 插件版本
     */
    version: string;

    /**
     * 插件作者
     */
    author: string;

    /**
     * 插件主入口
     */
    main?: string;

    /**
     * 插件路径
     */
    path: string;

    /**
     * 插件验证错误
     */
    validationError: string | null;

    /**
     * 插件状态
     */
    status: PluginStatus;

    /**
     * 插件类型
     */
    type: PluginType;

    /**
     * NPM包名称，用于远程插件
     */
    npmPackage?: string;

    /**
     * 插件页面视图路径
     * 如果存在，表示插件带有一个可以在主界面显示的视图
     */
    pagePath?: string;
}

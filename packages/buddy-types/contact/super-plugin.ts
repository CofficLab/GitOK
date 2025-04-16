import { SuperAction } from "./super-action.js";

/**
 * 验证结果
 */
export interface ValidationResult {
    isValid: boolean;
    errors: string[];
}

/**
 * 插件状态
 * - inactive: 未激活（默认状态）
 * - active: 已激活
 * - error: 出错
 * - disabled: 已禁用
 */
export type PluginStatus = 'inactive' | 'active' | 'error' | 'disabled';

/**
 * 插件类型
 * - user: 用户安装的插件
 * - dev: 开发中的插件
 */
export type PluginType = 'user' | 'dev' | 'remote';

export interface GetActionsArgs {
    keyword?: string;
    overlaidApp?: boolean;
}

/**
 * 插件信息接口
 */
export interface SuperPlugin {
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
     * 插件验证状态
     */
    validation?: ValidationResult | null;

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

    hasPage: boolean;

    getActions(args: GetActionsArgs): Promise<SuperAction[]>;
}

import { ActionStatus, SuperAction, ValidationResult, ViewMode } from "@coffic/buddy-types";
import { logger } from "../managers/LogManager.js";
import { pluginManager } from "../managers/PluginManager.js";
import { PluginEntity } from "./PluginEntity.js";
import { SendableAction } from "@/types/sendable-action.js";

/**
 * 插件动作实体类
 */
export class ActionEntity implements SendableAction {
    // 基本信息
    globalId: string;
    id: string;
    description: string;
    icon: string;
    pluginId: string;
    keywords: string[];
    category?: string;

    // 视图相关
    viewPath?: string;
    viewMode?: ViewMode;
    devTools?: boolean;

    // 状态信息
    status: ActionStatus = 'ready';
    error?: string;
    lastExecuteTime?: Date;
    disabled: boolean = false;

    // 验证结果
    validation?: ValidationResult;

    /**
     * 构造函数
     */
    constructor(action: {
        id: string;
        description?: string;
        icon?: string;
        pluginId: string;
        keywords?: string[];
        category?: string;
        viewPath?: string;
        viewMode?: ViewMode;
        devTools?: boolean;
    }) {
        this.id = action.id;
        this.globalId = action.pluginId + ':' + action.id;
        this.description = action.description || '';
        this.icon = action.icon || '';
        this.pluginId = action.pluginId;
        this.keywords = action.keywords || [];
        this.category = action.category;
        this.viewPath = action.viewPath;
        this.viewMode = action.viewMode;
        this.devTools = action.devTools;

        // 执行验证
        this.validate();
    }

    /**
     * 验证动作
     */
    private validate(): void {
        const errors: string[] = [];

        // 验证必填字段
        if (!this.id) {
            errors.push('动作ID不能为空');
        }
        if (!this.pluginId) {
            errors.push('插件ID不能为空');
        }

        // 验证视图模式
        if (this.viewMode && !['embedded', 'window'].includes(this.viewMode)) {
            errors.push('无效的视图模式');
        }

        // 设置验证结果
        this.validation = {
            isValid: errors.length === 0,
            errors,
        };

        // 如果验证失败，设置错误状态
        if (!this.validation.isValid) {
            this.setStatus('error', errors.join('; '));
        }
    }

    /**
     * 静态工厂方法：从原始数据创建实例
     */
    static fromRawAction(
        action: SuperAction,
        pluginId: string
    ): ActionEntity {
        return new ActionEntity({
            ...action,
            pluginId,
            keywords: [],
        });
    }

    static fromSendableAction(action: SendableAction): ActionEntity {
        return new ActionEntity({
            ...action,
            pluginId: action.pluginId,
            keywords: [],
        });
    }

    /**
     * 设置动作状态
     */
    setStatus(status: ActionStatus, error?: string): void {
        this.status = status;
        this.error = error;

        if (status === 'completed' || status === 'error') {
            this.lastExecuteTime = new Date();
        }
    }

    /**
     * 禁用动作
     */
    disable(): void {
        this.disabled = true;
        this.status = 'disabled';
    }

    /**
     * 启用动作
     */
    enable(): void {
        this.disabled = false;
        this.status = 'ready';
    }

    /**
     * 开始执行
     */
    beginExecute(): void {
        if (this.disabled) {
            throw new Error('动作已禁用');
        }
        this.status = 'executing';
    }

    /**
     * 完成执行
     */
    completeExecute(): void {
        this.status = 'completed';
        this.lastExecuteTime = new Date();
    }

    /**
     * 执行出错
     */
    executeError(error: string): void {
        this.status = 'error';
        this.error = error;
        this.lastExecuteTime = new Date();
    }

    /**
     * 重置状态
     */
    reset(): void {
        this.status = 'ready';
        this.error = undefined;
    }

    /**
     * 检查动作是否可执行
     */
    canExecute(): boolean {
        return !this.disabled && this.status !== 'executing';
    }

    /**
     * 获取动作视图内容
     * @param actionId 动作ID
     * @returns 视图内容
     */
    async getViewContent(): Promise<string> {
        logger.info(`获取动作视图: ${this.globalId}`);

        // 解析插件ID
        const [pluginId] = this.globalId.split(':');
        if (!pluginId) {
            throw new Error(`无效的动作ID: ${this.globalId}`);
        }

        // 获取插件实例
        const plugin = await this.getPlugin();
        if (!plugin) {
            throw new Error(`未找到插件: ${pluginId}`);
        }

        if (!this.viewPath) {
            throw new Error(`动作 ${this.globalId} 没有关联视图`);
        }

        // 获取视图内容
        return this.viewPath;
    }

    async getPlugin(): Promise<PluginEntity | null> {
        return await pluginManager.getPlugin(this.pluginId);
    }
}

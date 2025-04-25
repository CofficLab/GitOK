/**
 * 动作状态
 * - ready: 就绪，可以执行
 * - executing: 执行中
 * - completed: 执行完成
 * - error: 执行出错
 * - disabled: 已禁用
 */
export type ActionStatus =
    | 'ready'
    | 'executing'
    | 'completed'
    | 'error'
    | 'disabled';

/**
* 动作视图模式
*/
export type ViewMode = 'embedded' | 'window';

/**
 * 插件动作接口
 */
export interface SendableAction {
    /**
     * 全局ID
     */
    globalId: string;

    /**
     * 在插件的命名空间中的动作ID
     */
    id: string;

    /**
     * 插件ID
     */
    pluginId: string;

    /**
     * 动作描述
     */
    description?: string;

    /**
     * 动作图标
     */
    icon?: string;

    /**
     * 视图路径
     */
    viewPath?: string;

    /**
     * 视图模式
     */
    viewMode?: 'embedded' | 'window';

    /**
     * 是否启用开发者工具
     */
    devTools?: boolean;
}

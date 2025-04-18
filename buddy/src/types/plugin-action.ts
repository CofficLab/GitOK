/**
 * 插件动作实体接口
 */
export interface PluginActionEntity {
    /**
     * 动作的唯一标识符
     */
    id: string;

    /**
     * 动作名称
     */
    name: string;

    /**
     * 动作描述
     */
    description?: string;

    /**
     * 动作的执行函数
     */
    execute: (...args: any[]) => Promise<any>;

    /**
     * 动作的关键词，用于搜索和过滤
     */
    keywords?: string[];

    /**
     * 动作是否启用
     */
    enabled?: boolean;
} 
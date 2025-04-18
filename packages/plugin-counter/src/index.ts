import { GetActionsArgs, SuperAction, SuperPlugin } from '@coffic/buddy-types';

// 插件ID
const PLUGIN_ID = 'sample-plugin-with-page';

// 插件对象
export const plugin: SuperPlugin = {
    id: PLUGIN_ID,
    name: '示例页面插件',
    description: '这是一个带有主页面的示例插件',
    version: '1.0.0',
    author: 'Coffic',
    path: '',
    type: 'user',

    /**
     * 获取插件提供的动作列表
     * @param {GetActionsArgs} args 上下文信息
     * @returns {Promise<SuperAction[]>} 动作列表
     */
    async getActions(args: GetActionsArgs): Promise<SuperAction[]> {
        const counterAction: SuperAction = {
            id: 'counter',
            description: '计数器',
            icon: 'counter',
            pluginId: PLUGIN_ID,
            globalId: `${PLUGIN_ID}-counter`,
            viewPath: 'page.html',
        };

        return [counterAction];
    },

    /**
     * 执行插件动作
     * @param {string} actionId 要执行的动作ID
     * @param {any} params 动作参数
     * @returns {Promise<any>} 动作执行结果
     */
    async executeAction(actionId: string, params: any): Promise<any> {
        return { success: true, message: '不支持执行动作' };
    },
};
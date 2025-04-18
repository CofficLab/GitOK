import { exec } from 'child_process';
import { GetActionsArgs, SuperAction, SuperPlugin, ExecuteResult } from '@coffic/buddy-types';

// 插件信息
const plugin: SuperPlugin = {
    name: '端口进程管理',
    description: '管理端口占用进程，支持快速结束指定端口的进程',
    version: '1.0.0',
    author: 'Coffic',
    id: '',
    path: '',
    type: 'user',

    /**
     * 获取插件提供的动作列表
     * @param {GetActionsArgs} args 插件上下文
     * @returns {Promise<SuperAction[]>} 动作列表
     */
    async getActions(args: GetActionsArgs): Promise<SuperAction[]> {
        const { keyword = '' } = args;
        const portRegex = /^[0-9]{1,5}$/;

        if (portRegex.test(keyword)) {
            // 创建一个符合SuperAction接口的对象
            const action: SuperAction = {
                id: 'killPort',
                description: `结束端口 ${keyword} 的进程`,
                icon: '🔌',
                globalId: '',
                pluginId: ''
            };

            // 传递端口参数，在executeAction时使用
            return [action];
        }

        return [];
    },

    /**
     * 执行插件动作
     * @param {string} actionId 要执行的动作ID
     * @param {string} port 端口号
     * @returns {Promise<ExecuteResult>} 动作执行结果
     */
    async executeAction(actionId: string, port: string): Promise<ExecuteResult> {
        if (actionId === 'killPort') {
            // 验证端口号是否有效
            const portRegex = /^[0-9]{1,5}$/;
            if (!portRegex.test(port)) {
                return {
                    success: false,
                    message: `无效的端口号: ${port}`
                };
            }

            const cmd =
                process.platform === 'win32'
                    ? `netstat -ano | findstr :${port}`
                    : `lsof -i :${port}`;

            return new Promise<ExecuteResult>((resolve, reject) => {
                exec(cmd, (error, stdout) => {
                    if (error) {
                        // 如果是因为没有找到进程导致的错误，返回友好提示
                        if (error.code === 1) {
                            resolve({
                                success: false,
                                message: `未找到占用端口 ${port} 的进程`
                            });
                            return;
                        }

                        reject(error);
                        return;
                    }

                    const lines = stdout.split('\n');
                    if (lines.length > 0) {
                        const pid =
                            process.platform === 'win32'
                                ? lines[0].split(/\s+/)[4]
                                : lines[1]?.split(/\s+/)[1];

                        if (pid) {
                            exec(`kill -9 ${pid}`, (error) => {
                                if (error) {
                                    reject(error);
                                } else {
                                    resolve({
                                        success: true,
                                        message: `成功终止端口 ${port} 的进程`,
                                    });
                                }
                            });
                        } else {
                            resolve({
                                success: false,
                                message: `未找到占用端口 ${port} 的进程`,
                            });
                        }
                    } else {
                        resolve({
                            success: false,
                            message: `未找到占用端口 ${port} 的进程`,
                        });
                    }
                });
            });
        }

        // 如果不是killPort动作，返回失败结果
        return {
            success: false,
            message: `未知的动作: ${actionId}`
        };
    },

    /**
     * 获取视图内容
     * @param {string} viewPath 视图路径
     * @returns {Promise<string>} HTML内容
     */
    async getViewContent(viewPath: string): Promise<string> {
        // 这个插件没有视图，但需要实现接口
        return '';
    },
};

// 导出插件
export = plugin; 
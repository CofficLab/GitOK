import { app } from 'electron';
import { join } from 'path';
import { PluginRepo } from './PluginRepo.js';
import { PluginType } from '@coffic/buddy-types';

/**
 * 用户插件仓库
 * 负责从磁盘读取插件信息
 */
export class PluginRepoUser extends PluginRepo {
    private static instance: PluginRepoUser;

    private constructor() {
        const userDataPath = app.getPath('userData');
        super(join(userDataPath, 'plugins'));
    }

    /**
     * 获取实例
     */
    public static getInstance(): PluginRepoUser {
        if (!PluginRepoUser.instance) {
            PluginRepoUser.instance = new PluginRepoUser();
        }
        return PluginRepoUser.instance;
    }

    protected getPluginType(): PluginType {
        return 'user';
    }
}

// 导出单例
export const userPluginDB = PluginRepoUser.getInstance();

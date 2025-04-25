import { dirname, join } from 'path';
import { PluginRepo } from './PluginRepo.js';
import { PluginType } from '@coffic/buddy-types';

/**
 * 开发插件仓库
 */
export class PluginRepoDev extends PluginRepo {
    private static instance: PluginRepoDev;

    private constructor() {
        const dir = join(dirname(process.cwd()), 'packages');
        super(dir);
    }

    /**
     * 获取实例
     */
    public static getInstance(): PluginRepoDev {
        if (!PluginRepoDev.instance) {
            PluginRepoDev.instance = new PluginRepoDev();
        }
        return PluginRepoDev.instance;
    }

    protected getPluginType(): PluginType {
        return 'dev';
    }
}

// 导出单例
export const devPluginDB = PluginRepoDev.getInstance();

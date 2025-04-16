/**
 * 插件数据库
 * 负责从磁盘读取插件信息
 */
import { app } from 'electron';
import { join } from 'path';
import { PluginEntity } from '../entities/PluginEntity.js';
import { PackageDB } from './PackageDB.js';
import { PluginType } from '@coffic/buddy-types';

export class UserPackageDB extends PackageDB {
    private static instance: UserPackageDB;

    private constructor() {
        const userDataPath = app.getPath('userData');
        super(join(userDataPath, 'plugins'));
    }

    /**
     * 获取 PluginDB 实例
     */
    public static getInstance(): UserPackageDB {
        if (!UserPackageDB.instance) {
            UserPackageDB.instance = new UserPackageDB();
        }
        return UserPackageDB.instance;
    }

    protected getPluginType(): PluginType {
        return 'user';
    }

    /**
     * 根据插件ID查找插件
     * @param id 插件ID
     * @returns 找到的插件实例，如果未找到则返回 null
     */
    public async find(id: string): Promise<PluginEntity | null> {
        return (await this.getAllPlugins()).find((plugin) => plugin.id === id) || null;
    }

    /**
     * 根据插件ID判断插件是否存在
     * @param id 插件ID
     * @returns 插件是否存在
     */
    public async has(id: string): Promise<boolean> {
        return (await this.getAllPlugins()).some((plugin) => plugin.id === id);
    }
}

// 导出单例
export const userPluginDB = UserPackageDB.getInstance();

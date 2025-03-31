/**
 * 插件数据库
 * 负责从磁盘读取插件信息
 */
import { app } from 'electron';
import { join } from 'path';
import { PluginEntity } from '../entities/PluginEntity';
import { logger } from '../managers/LogManager';
import { DiskPluginDB } from './DiskPluginDB';

export class UserPluginDB extends DiskPluginDB {
  private static instance: UserPluginDB;

  private constructor() {
    const userDataPath = app.getPath('userData');
    super(join(userDataPath, 'plugins'));
  }

  /**
   * 获取 PluginDB 实例
   */
  public static getInstance(): UserPluginDB {
    if (!UserPluginDB.instance) {
      UserPluginDB.instance = new UserPluginDB();
    }
    return UserPluginDB.instance;
  }

  protected getPluginType(): 'dev' | 'user' {
    return 'user';
  }

  /**
   * 根据插件ID查找插件
   * @param id 插件ID
   * @returns 找到的插件实例，如果未找到则返回 null
   */
  public async find(id: string): Promise<PluginEntity | null> {
    try {
      const plugins = await this.getAllPlugins();
      return plugins.find((plugin) => plugin.id === id) || null;
    } catch (error) {
      logger.error(`查找插件失败: ${id}`, error);
      return null;
    }
  }
}

// 导出单例
export const userPluginDB = UserPluginDB.getInstance();

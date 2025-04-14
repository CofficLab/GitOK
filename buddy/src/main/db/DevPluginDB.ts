/**
 * 开发插件数据库
 * 负责从项目packages目录读取开发中的插件信息
 */
import { dirname, join } from 'path';
import { DiskPluginDB } from './DiskPluginDB';
import { PluginEntity } from '../entities/PluginEntity';
import { logger } from '../managers/LogManager';

export class DevPluginDB extends DiskPluginDB {
  private static instance: DevPluginDB;

  private constructor() {
    const dir = join(dirname(process.cwd()), 'packages');
    super(dir);
  }

  /**
   * 获取 DevPluginDB 实例
   */
  public static getInstance(): DevPluginDB {
    if (!DevPluginDB.instance) {
      DevPluginDB.instance = new DevPluginDB();
    }
    return DevPluginDB.instance;
  }

  protected getPluginType(): 'dev' | 'user' {
    return 'dev';
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
      logger.error(`查找开发插件失败: ${id}`, error);
      return null;
    }
  }
}

// 导出单例
export const devPluginDB = DevPluginDB.getInstance();

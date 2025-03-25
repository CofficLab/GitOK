import fs from 'fs';
import path from 'path';
import os from 'os';
import { Logger } from './logger';

const logger = new Logger('WorkspaceCache');

/**
 * 工作区缓存工具
 * 用于缓存工作区路径和当前应用ID到本地文件
 */
export class WorkspaceCache {
  private static readonly CACHE_DIR = path.join(
    os.homedir(),
    '.coffic',
    'ide-workspace'
  );
  private static readonly CACHE_FILE = path.join(
    WorkspaceCache.CACHE_DIR,
    'workspace.json'
  );
  private static readonly CURRENT_APP_KEY = '_current_app_';

  /**
   * 清理工作区路径
   * 去除file://前缀和URL编码
   */
  private static cleanWorkspacePath(workspace: string | null): string | null {
    if (!workspace) return null;

    // 去除file://前缀
    let cleanPath = workspace.replace(/^file:\/\//, '');

    // 处理URL编码
    try {
      cleanPath = decodeURIComponent(cleanPath);
    } catch (e) {
      logger.error('解码工作区路径失败:', e);
    }

    return cleanPath;
  }

  /**
   * 保存当前应用ID到缓存
   * @param appId 应用标识符
   */
  static async saveCurrentApp(appId: string): Promise<void> {
    try {
      // 确保缓存目录存在
      if (!fs.existsSync(this.CACHE_DIR)) {
        fs.mkdirSync(this.CACHE_DIR, { recursive: true });
      }

      // 读取现有缓存
      let cacheData: Record<string, any> = {};
      if (fs.existsSync(this.CACHE_FILE)) {
        const content = fs.readFileSync(this.CACHE_FILE, 'utf8');
        try {
          cacheData = JSON.parse(content);
        } catch (e) {
          logger.error('解析缓存文件失败，将重新创建', e);
        }
      }

      // 更新当前应用ID
      cacheData[this.CURRENT_APP_KEY] = appId;

      // 写入缓存文件
      fs.writeFileSync(
        this.CACHE_FILE,
        JSON.stringify(cacheData, null, 2),
        'utf8'
      );
      logger.debug(`缓存当前应用ID成功: ${appId}`);
    } catch (error) {
      logger.error('保存当前应用ID缓存失败:', error);
    }
  }

  /**
   * 获取当前应用ID
   * @returns 当前应用ID，如果不存在则返回空字符串
   */
  static getCurrentApp(): string {
    try {
      if (!fs.existsSync(this.CACHE_FILE)) {
        logger.debug('缓存文件不存在');
        return '';
      }

      const content = fs.readFileSync(this.CACHE_FILE, 'utf8');
      const cacheData = JSON.parse(content);

      return cacheData[this.CURRENT_APP_KEY] || '';
    } catch (error) {
      logger.error('读取当前应用ID缓存失败:', error);
      return '';
    }
  }

  /**
   * 保存工作区信息到缓存
   * @param appId 应用标识符
   * @param workspace 工作区路径
   */
  static async saveWorkspace(
    appId: string,
    workspace: string | null
  ): Promise<void> {
    try {
      // 确保缓存目录存在
      if (!fs.existsSync(this.CACHE_DIR)) {
        fs.mkdirSync(this.CACHE_DIR, { recursive: true });
      }

      // 清理工作区路径
      const cleanWorkspace = this.cleanWorkspacePath(workspace);

      // 读取现有缓存
      let cacheData: Record<string, any> = {};
      if (fs.existsSync(this.CACHE_FILE)) {
        const content = fs.readFileSync(this.CACHE_FILE, 'utf8');
        try {
          cacheData = JSON.parse(content);
        } catch (e) {
          logger.error('解析缓存文件失败，将重新创建', e);
        }
      }

      // 更新缓存
      cacheData[appId] = cleanWorkspace;

      // 写入缓存文件
      fs.writeFileSync(
        this.CACHE_FILE,
        JSON.stringify(cacheData, null, 2),
        'utf8'
      );
      logger.debug(`缓存工作区成功: ${appId} => ${cleanWorkspace}`);
    } catch (error) {
      logger.error('保存工作区缓存失败:', error);
    }
  }

  /**
   * 从缓存中获取工作区信息
   * @param appId 应用标识符，如果为空则尝试使用当前缓存的应用ID
   * @returns 工作区路径，如果不存在则返回null
   */
  static getWorkspace(appId?: string): string | null {
    try {
      if (!fs.existsSync(this.CACHE_FILE)) {
        logger.debug('缓存文件不存在');
        return null;
      }

      const content = fs.readFileSync(this.CACHE_FILE, 'utf8');
      const cacheData = JSON.parse(content);

      // 如果没有提供appId，使用缓存中的当前应用ID
      const actualAppId = appId || cacheData[this.CURRENT_APP_KEY] || '';
      if (!actualAppId) {
        logger.error('未提供应用ID且缓存中没有当前应用ID');
        return null;
      }

      // 获取并确保路径格式正确
      const workspace = cacheData[actualAppId] || null;

      // 如果路径存在但不是有效路径，返回null
      if (workspace && !fs.existsSync(workspace)) {
        logger.error(`缓存的工作区路径不存在: ${workspace}`);
        return null;
      }

      return workspace;
    } catch (error) {
      logger.error('读取工作区缓存失败:', error);
      return null;
    }
  }

  /**
   * 清除指定应用的工作区缓存
   * @param appId 应用标识符
   */
  static clearWorkspace(appId: string): void {
    try {
      if (!fs.existsSync(this.CACHE_FILE)) {
        return;
      }

      const content = fs.readFileSync(this.CACHE_FILE, 'utf8');
      const cacheData = JSON.parse(content);

      if (cacheData[appId]) {
        delete cacheData[appId];
        fs.writeFileSync(
          this.CACHE_FILE,
          JSON.stringify(cacheData, null, 2),
          'utf8'
        );
        logger.debug(`清除工作区缓存成功: ${appId}`);
      }
    } catch (error) {
      logger.error('清除工作区缓存失败:', error);
    }
  }
}

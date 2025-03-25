import fs from 'fs';
import path from 'path';
import os from 'os';
import { Logger } from '../utils/logger';

const logger = new Logger('CursorService');

/**
 * Cursor工作空间服务
 */
export class CursorService {
  /**
   * 获取Cursor的工作空间路径
   */
  async getWorkspace(): Promise<string | null> {
    try {
      const storagePath = await this.findStoragePath();
      if (!storagePath) {
        logger.error('未找到Cursor存储文件');
        return null;
      }

      // 读取并解析存储文件
      const content = fs.readFileSync(storagePath, 'utf8');
      return this.parseCursorJson(content);
    } catch (error) {
      logger.error('获取Cursor工作空间失败:', error);
      return null;
    }
  }

  /**
   * 查找Cursor存储文件路径
   */
  private async findStoragePath(): Promise<string | null> {
    const home = os.homedir();
    let possiblePaths: string[] = [];

    // 根据操作系统添加可能的路径
    if (process.platform === 'darwin') {
      possiblePaths = [
        path.join(home, 'Library/Application Support/Cursor/storage.json'),
        path.join(
          home,
          'Library/Application Support/Cursor/User/globalStorage/storage.json'
        ),
      ];
    } else if (process.platform === 'win32') {
      const appData = process.env.APPDATA;
      if (appData) {
        possiblePaths = [
          path.join(appData, 'Cursor/storage.json'),
          path.join(appData, 'Cursor/User/globalStorage/storage.json'),
        ];
      }
    } else if (process.platform === 'linux') {
      possiblePaths = [
        path.join(home, '.config/Cursor/storage.json'),
        path.join(home, '.config/Cursor/User/globalStorage/storage.json'),
      ];
    }

    // 返回第一个存在的文件路径
    for (const filePath of possiblePaths) {
      if (fs.existsSync(filePath)) {
        logger.debug(`找到Cursor存储文件: ${filePath}`);
        return filePath;
      }
    }

    return null;
  }

  /**
   * 解析Cursor JSON格式的存储文件
   */
  private parseCursorJson(content: string): string | null {
    try {
      const data = JSON.parse(content);

      // 从 windowsState.lastActiveWindow.folder 获取工作区路径
      const windowState = data.windowsState;
      if (windowState?.lastActiveWindow?.folder) {
        const folder = windowState.lastActiveWindow.folder;
        // 处理路径
        const decodedPath = decodeURIComponent(folder);
        logger.info(`找到Cursor工作区: ${decodedPath}`);
        return decodedPath;
      }

      logger.error('无法从JSON中获取工作区路径');
      return null;
    } catch (error) {
      logger.error('解析JSON失败:', error);
      return null;
    }
  }
}

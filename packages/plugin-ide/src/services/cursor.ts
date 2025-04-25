import fs from 'fs';
import path from 'path';
import os from 'os';
import { BaseIDEService } from './base';
import { Logger } from '../utils/logger';
import { IDEServiceFactory } from './ide_factory';

const logger = new Logger('CursorService');

/**
 * Cursor工作空间服务
 */
export class CursorService extends BaseIDEService {
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
      const workspacePath = this.parseCursorJson(content);

      // 使用IDEServiceFactory清理路径
      if (workspacePath) {
        return IDEServiceFactory.cleanWorkspacePath(workspacePath);
      }

      return null;
    } catch (error) {
      logger.error('获取Cursor工作空间失败:', error);
      return null;
    }
  }

  /**
   * 查找Cursor存储文件路径
   */
  async findStoragePath(): Promise<string | null> {
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
   * 解析dev container路径
   * 从vscode-remote URL中提取实际的本地路径
   */
  private parseDevContainerPath(containerPath: string): string | null {
    try {
      // 检查是否是dev container路径
      if (containerPath.startsWith('vscode-remote://dev-container+')) {
        // 提取编码的部分
        const encodedPart = containerPath.split('vscode-remote://dev-container+')[1].split('/')[0];

        // URL解码
        const jsonStr = decodeURIComponent(encodedPart);

        try {
          const containerInfo = JSON.parse(jsonStr);

          // 返回本地路径
          if (containerInfo.hostPath) {
            logger.debug(`解析dev container路径成功: ${containerInfo.hostPath}`);
            return containerInfo.hostPath;
          }
        } catch (jsonError) {
          // 如果JSON解析失败，尝试使用base64解码（向后兼容）
          try {
            const jsonStr = Buffer.from(encodedPart, 'base64').toString();
            const containerInfo = JSON.parse(jsonStr);

            if (containerInfo.hostPath) {
              logger.debug(`通过base64解析dev container路径成功: ${containerInfo.hostPath}`);
              return containerInfo.hostPath;
            }
          } catch (base64Error) {
            logger.error('base64解析也失败，可能格式发生了变化');
          }
        }
      }

      return null;
    } catch (error) {
      logger.error('解析dev container路径失败:', error);
      return null;
    }
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

        // 首先尝试解析是否为dev container路径
        const containerPath = this.parseDevContainerPath(folder);
        if (containerPath) {
          return containerPath;
        }

        // 如果不是dev container路径，按常规方式处理
        let workspacePath = decodeURIComponent(folder);

        // 移除file://前缀，与VSCode路径格式保持一致
        if (workspacePath.startsWith('file://')) {
          workspacePath = workspacePath.replace('file://', '');
          // 在Windows上需要额外处理
          if (process.platform === 'win32') {
            workspacePath = workspacePath.replace(/^\//, '');
          }
        }

        logger.info(`找到Cursor工作区: ${workspacePath}`);
        return workspacePath;
      }

      logger.error('无法从JSON中获取工作区路径');
      return null;
    } catch (error) {
      logger.error('解析JSON失败:', error);
      return null;
    }
  }
}

import fs from 'fs';
import path from 'path';
import os from 'os';
import { Logger } from '../utils/logger';
import sqlite3 from 'sqlite3';
import { promisify } from 'util';

const logger = new Logger('VSCodeService');

interface SQLiteRow {
  key: string;
  value: Buffer | string;
}

/**
 * VSCode工作空间服务
 */
export class VSCodeService {
  /**
   * 获取VSCode的工作空间路径
   */
  async getWorkspace(): Promise<string | null> {
    try {
      const storagePath = await this.findStoragePath();
      if (!storagePath) {
        logger.error('未找到VSCode存储文件');
        return null;
      }

      // 根据文件类型选择解析方法
      if (storagePath.endsWith('.json')) {
        return this.parseJsonStorage(storagePath);
      } else if (storagePath.endsWith('.vscdb')) {
        return this.parseSqliteStorage(storagePath);
      }

      return null;
    } catch (error) {
      logger.error('获取VSCode工作空间失败:', error);
      return null;
    }
  }

  /**
   * 查找VSCode存储文件路径
   */
  private async findStoragePath(): Promise<string | null> {
    const home = os.homedir();
    let possiblePaths: string[] = [];

    // 根据操作系统添加可能的路径
    if (process.platform === 'darwin') {
      possiblePaths = [
        path.join(home, 'Library/Application Support/Code/storage.json'),
        path.join(
          home,
          'Library/Application Support/Code/User/globalStorage/state.vscdb'
        ),
        path.join(
          home,
          'Library/Application Support/Code/User/globalStorage/storage.json'
        ),
        path.join(
          home,
          'Library/Application Support/Code - Insiders/storage.json'
        ),
        path.join(
          home,
          'Library/Application Support/Code - Insiders/User/globalStorage/state.vscdb'
        ),
        path.join(
          home,
          'Library/Application Support/Code - Insiders/User/globalStorage/storage.json'
        ),
      ];
    } else if (process.platform === 'win32') {
      const appData = process.env.APPDATA;
      if (appData) {
        possiblePaths = [
          path.join(appData, 'Code/storage.json'),
          path.join(appData, 'Code/User/globalStorage/state.vscdb'),
          path.join(appData, 'Code/User/globalStorage/storage.json'),
        ];
      }
    } else if (process.platform === 'linux') {
      possiblePaths = [
        path.join(home, '.config/Code/storage.json'),
        path.join(home, '.config/Code/User/globalStorage/state.vscdb'),
        path.join(home, '.config/Code/User/globalStorage/storage.json'),
      ];
    }

    // 返回第一个存在的文件路径
    for (const filePath of possiblePaths) {
      if (fs.existsSync(filePath)) {
        logger.debug(`找到VSCode存储文件: ${filePath}`);
        return filePath;
      }
    }

    return null;
  }

  /**
   * 解析JSON格式的存储文件
   */
  private async parseJsonStorage(filePath: string): Promise<string | null> {
    try {
      const content = fs.readFileSync(filePath, 'utf8');
      const data = JSON.parse(content);
      let workspacePath: string | null = null;

      // 尝试从 openedPathsList 获取
      if (data.openedPathsList?.entries?.[0]?.folderUri) {
        workspacePath = data.openedPathsList.entries[0].folderUri;
      }
      // 尝试从 windowState 获取
      else if (data.windowState?.lastActiveWindow?.folderUri) {
        workspacePath = data.windowState.lastActiveWindow.folderUri;
      }

      if (workspacePath) {
        workspacePath = workspacePath.replace('file://', '');
        return decodeURIComponent(workspacePath);
      }

      return null;
    } catch (error) {
      logger.error('解析JSON存储文件失败:', error);
      return null;
    }
  }

  /**
   * 解析SQLite格式的存储文件
   */
  private async parseSqliteStorage(filePath: string): Promise<string | null> {
    return new Promise((resolve, reject) => {
      const db = new sqlite3.Database(
        filePath,
        sqlite3.OPEN_READONLY,
        (err) => {
          if (err) {
            logger.error('打开SQLite数据库失败:', err);
            resolve(null);
            return;
          }

          const query = `
          SELECT key, value FROM ItemTable 
          WHERE key LIKE '%workspace%' 
             OR key LIKE '%window%'
             OR key LIKE '%folder%'
          ORDER BY key DESC
        `;

          db.all(query, [], (err, rows: SQLiteRow[]) => {
            if (err) {
              logger.error('查询SQLite数据库失败:', err);
              db.close();
              resolve(null);
              return;
            }

            let workspacePath: string | null = null;

            for (const row of rows) {
              try {
                const value = row.value;
                if (!value) continue;

                // 将Buffer或字符串转换为字符串
                let jsonStr: string;
                if (Buffer.isBuffer(value)) {
                  jsonStr = value.toString('utf8');
                } else {
                  jsonStr = value;
                }

                const data = JSON.parse(jsonStr);

                // 检查常见的路径位置
                if (data.folderUri) {
                  workspacePath = data.folderUri.replace('file://', '');
                  break;
                }
                if (data.workspace?.folders?.[0]?.uri) {
                  workspacePath = data.workspace.folders[0].uri.replace(
                    'file://',
                    ''
                  );
                  break;
                }
              } catch (e) {
                continue; // 忽略解析失败的项
              }
            }

            db.close();
            resolve(workspacePath ? decodeURIComponent(workspacePath) : null);
          });
        }
      );
    });
  }
}

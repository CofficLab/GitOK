const fs = require('fs').promises;
const path = require('path');
const sqlite3 = require('sqlite3');
const os = require('os');
const { promisify } = require('util');

/**
 * VSCode 工作区插件
 *
 * 功能：
 * 1. 检测当前被覆盖的应用是否是 VSCode
 * 2. 如果是 VSCode，读取其工作区信息
 * 3. 在动作列表中显示工作区信息
 */

class VSCodeWorkspacePlugin {
  constructor() {
    this.tag = 'VSCodeWorkspacePlugin';
  }

  /**
   * 获取 VSCode 存储文件路径
   */
  async getStoragePath() {
    const home = os.homedir();
    let possiblePaths = [];

    if (process.platform === 'darwin') {
      // macOS
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
        path.join(home, 'Library/Application Support/VSCodium/storage.json'),
        path.join(
          home,
          'Library/Application Support/VSCodium/User/globalStorage/state.vscdb'
        ),
        path.join(
          home,
          'Library/Application Support/VSCodium/User/globalStorage/storage.json'
        ),
      ];
    } else if (process.platform === 'win32') {
      // Windows
      const appData = process.env.APPDATA;
      possiblePaths = [
        path.join(appData, 'Code/storage.json'),
        path.join(appData, 'Code/User/globalStorage/state.vscdb'),
        path.join(appData, 'Code/User/globalStorage/storage.json'),
        path.join(appData, 'Code - Insiders/storage.json'),
        path.join(appData, 'Code - Insiders/User/globalStorage/state.vscdb'),
        path.join(appData, 'Code - Insiders/User/globalStorage/storage.json'),
        path.join(appData, 'VSCodium/storage.json'),
        path.join(appData, 'VSCodium/User/globalStorage/state.vscdb'),
        path.join(appData, 'VSCodium/User/globalStorage/storage.json'),
      ];
    } else if (process.platform === 'linux') {
      // Linux
      possiblePaths = [
        path.join(home, '.config/Code/storage.json'),
        path.join(home, '.config/Code/User/globalStorage/state.vscdb'),
        path.join(home, '.config/Code/User/globalStorage/storage.json'),
        path.join(home, '.config/Code - Insiders/storage.json'),
        path.join(
          home,
          '.config/Code - Insiders/User/globalStorage/state.vscdb'
        ),
        path.join(
          home,
          '.config/Code - Insiders/User/globalStorage/storage.json'
        ),
        path.join(home, '.config/VSCodium/storage.json'),
        path.join(home, '.config/VSCodium/User/globalStorage/state.vscdb'),
        path.join(home, '.config/VSCodium/User/globalStorage/storage.json'),
      ];
    }

    // 检查文件是否存在
    for (const filePath of possiblePaths) {
      try {
        await fs.access(filePath);
        console.log(`[${this.tag}] 找到 VSCode 存储文件: ${filePath}`);
        return filePath;
      } catch (error) {
        // 文件不存在，继续检查下一个
        continue;
      }
    }

    console.error(`[${this.tag}] 未找到 VSCode 存储文件`);
    return null;
  }

  /**
   * 解析 VSCode JSON 格式的存储文件
   */
  async parseVSCodeJson(content) {
    try {
      const json = JSON.parse(content);

      // 尝试不同的数据结构
      let folderUri;

      // 结构 1: openedPathsList.entries
      const workspaceStorage = json.openedPathsList;
      const workspaces = workspaceStorage?.entries;
      if (workspaces && workspaces.length > 0) {
        const lastWorkspace = workspaces[0];
        folderUri = lastWorkspace.folderUri;
      }

      // 结构 2: windowState.lastActiveWindow
      if (!folderUri) {
        const windowState = json.windowState;
        const lastWindow = windowState?.lastActiveWindow;
        folderUri = lastWindow?.folderUri;
      }

      if (!folderUri) {
        console.error(`[${this.tag}] 无法从 JSON 中获取工作区路径`);
        return null;
      }

      // 处理路径
      const cleanPath = folderUri.replace('file://', '');
      const decodedPath = decodeURIComponent(cleanPath);

      console.log(`[${this.tag}] 找到 VSCode 工作区: ${decodedPath}`);
      return decodedPath;
    } catch (error) {
      console.error(`[${this.tag}] 解析 JSON 失败:`, error);
      return null;
    }
  }

  /**
   * 解析 VSCode SQLite 数据库内容
   */
  async parseVSCodeDatabase(filePath) {
    return new Promise(async (resolve, reject) => {
      try {
        // 创建临时目录
        const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), 'vscode_db_'));
        const tempPath = path.join(tempDir, 'state.vscdb');

        // 复制数据库文件到临时目录
        await fs.copyFile(filePath, tempPath);

        // 打开数据库
        const db = new sqlite3.Database(tempPath);
        const dbAll = promisify(db.all.bind(db));

        // 查询最近的工作区
        const results = await dbAll(`
          SELECT key, value FROM ItemTable 
          WHERE key LIKE '%window%'
             OR key LIKE '%workspace%'
             OR key LIKE '%folder%'
             OR key LIKE '%recent%'
             OR key LIKE '%history%'
             OR key LIKE '%state.global%'
             OR key = 'history.recentlyOpenedPathsList'
          ORDER BY key
        `);

        console.log(`[${this.tag}] 查询到 ${results.length} 条记录`);

        for (const row of results) {
          const { key, value } = row;
          console.log(`[${this.tag}] 处理数据库记录 - Key: ${key}`);

          if (!value) continue;

          let jsonStr;
          if (Buffer.isBuffer(value)) {
            jsonStr = value.toString('utf8');
          } else if (typeof value === 'string') {
            jsonStr = value;
          } else {
            continue;
          }

          try {
            const data = JSON.parse(jsonStr);

            // 处理包含 entries 的数据结构
            if (data.entries && Array.isArray(data.entries)) {
              for (const entry of data.entries) {
                if (entry.folderUri) {
                  const cleanPath = entry.folderUri.replace('file://', '');
                  const decodedPath = decodeURIComponent(cleanPath);
                  db.close();
                  await fs.rm(tempDir, { recursive: true });
                  return resolve(decodedPath);
                }
              }
            }

            // 处理窗口状态
            if (key.includes('windowState') && data.lastActiveWindow) {
              const folderUri = data.lastActiveWindow.folderUri;
              if (folderUri) {
                const cleanPath = folderUri.replace('file://', '');
                const decodedPath = decodeURIComponent(cleanPath);
                db.close();
                await fs.rm(tempDir, { recursive: true });
                return resolve(decodedPath);
              }
            }
          } catch (error) {
            console.debug(`[${this.tag}] 解析记录失败: ${error}`);
            continue;
          }
        }

        db.close();
        await fs.rm(tempDir, { recursive: true });
        resolve(null);
      } catch (error) {
        console.error(`[${this.tag}] 解析数据库失败:`, error);
        resolve(null);
      }
    });
  }

  /**
   * 获取 VSCode 当前工作区
   */
  async getActiveWorkspace() {
    try {
      const storagePath = await this.getStoragePath();
      if (!storagePath) {
        return null;
      }

      const stats = await fs.stat(storagePath);
      if (!stats.isFile()) {
        return null;
      }

      if (storagePath.endsWith('.vscdb')) {
        // SQLite 数据库文件
        return await this.parseVSCodeDatabase(storagePath);
      } else {
        // JSON 文件
        const content = await fs.readFile(storagePath, 'utf8');
        return await this.parseVSCodeJson(content);
      }
    } catch (error) {
      console.error(`[${this.tag}] 获取 VSCode 工作区失败:`, error);
      return null;
    }
  }

  /**
   * 插件入口函数
   */
  async onAction(context) {
    // 检查当前被覆盖的应用是否是 VSCode
    const activeApp = context.activeApp;
    if (!activeApp || !activeApp.name.toLowerCase().includes('code')) {
      return [];
    }

    // 获取 VSCode 工作区
    const workspace = await this.getActiveWorkspace();
    if (!workspace) {
      return [];
    }

    // 返回动作列表
    return [
      {
        id: 'vscode-workspace',
        title: 'VSCode 工作区',
        description: workspace,
        icon: '📁',
        action: async () => {
          // 可以在这里添加点击动作，比如打开工作区
          console.log(`[${this.tag}] 点击了工作区: ${workspace}`);
        },
      },
    ];
  }
}

module.exports = new VSCodeWorkspacePlugin();

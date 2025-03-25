/**
 * IDE工作空间插件
 * 用于显示当前IDE的工作空间信息
 */

const fs = require('fs');
const path = require('path');
const os = require('os');

// 日志函数
const log = {
  info: function (message, ...args) {
    console.log(`[IDE工作空间] ${message}`, ...args);
  },
  error: function (message, ...args) {
    console.error(`[IDE工作空间] ${message}`, ...args);
  },
  debug: function (message, ...args) {
    console.log(`[IDE工作空间:调试] ${message}`, ...args);
  },
};

/**
 * 获取VSCode的工作空间路径
 * @returns {Promise<string|null>} 工作空间路径
 */
async function getVSCodeWorkspace() {
  try {
    const home = os.homedir();
    let storagePath = null;

    // 根据不同操作系统获取存储文件路径
    if (process.platform === 'darwin') {
      const possiblePaths = [
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

      for (const filePath of possiblePaths) {
        if (fs.existsSync(filePath)) {
          storagePath = filePath;
          break;
        }
      }
    } else if (process.platform === 'win32') {
      const appData = process.env.APPDATA;
      const possiblePaths = [
        path.join(appData, 'Code/storage.json'),
        path.join(appData, 'Code/User/globalStorage/state.vscdb'),
        path.join(appData, 'Code/User/globalStorage/storage.json'),
      ];

      for (const filePath of possiblePaths) {
        if (fs.existsSync(filePath)) {
          storagePath = filePath;
          break;
        }
      }
    } else if (process.platform === 'linux') {
      const possiblePaths = [
        path.join(home, '.config/Code/storage.json'),
        path.join(home, '.config/Code/User/globalStorage/state.vscdb'),
        path.join(home, '.config/Code/User/globalStorage/storage.json'),
      ];

      for (const filePath of possiblePaths) {
        if (fs.existsSync(filePath)) {
          storagePath = filePath;
          break;
        }
      }
    }

    if (!storagePath) {
      log.error('未找到VSCode存储文件');
      return null;
    }

    // 读取存储文件
    if (storagePath.endsWith('.json')) {
      const content = fs.readFileSync(storagePath, 'utf8');
      const data = JSON.parse(content);

      // 尝试不同的数据结构获取工作空间路径
      let workspacePath = null;

      // 尝试从 openedPathsList 获取
      if (data.openedPathsList && data.openedPathsList.entries) {
        const entry = data.openedPathsList.entries[0];
        if (entry && entry.folderUri) {
          workspacePath = entry.folderUri.replace('file://', '');
        }
      }

      // 尝试从 windowState 获取
      if (
        !workspacePath &&
        data.windowState &&
        data.windowState.lastActiveWindow
      ) {
        const lastWindow = data.windowState.lastActiveWindow;
        if (lastWindow.folderUri) {
          workspacePath = lastWindow.folderUri.replace('file://', '');
        }
      }

      if (workspacePath) {
        return decodeURIComponent(workspacePath);
      }
    }
    // TODO: 处理 .vscdb 文件的情况

    return null;
  } catch (error) {
    log.error('获取VSCode工作空间失败:', error);
    return null;
  }
}

// 插件信息
const plugin = {
  name: 'IDE工作空间',
  description: '显示当前IDE的工作空间信息',
  version: '1.0.0',
  author: 'Coffic',

  /**
   * 获取插件提供的动作列表
   * @param {Object} context 插件上下文
   * @param {string} context.keyword 搜索关键词
   * @param {string} context.overlaidApp 被覆盖应用名称
   * @returns {Promise<Array>} 动作列表
   */
  async getActions({ keyword = '', overlaidApp = '' }) {
    log.info(`获取动作列表，关键词: "${keyword}", 应用: "${overlaidApp}"`);

    // 检查是否为IDE应用
    const isIDE =
      overlaidApp.toLowerCase().includes('code') ||
      overlaidApp.toLowerCase().includes('vscode') ||
      overlaidApp.toLowerCase().includes('visual studio code');

    if (!isIDE) {
      log.debug('不是IDE应用，返回空列表');
      return [];
    }

    // 创建动作列表
    const actions = [
      {
        id: 'show_workspace',
        title: '显示工作空间',
        description: '显示当前IDE的工作空间路径',
        icon: '📁',
      },
    ];

    // 如果有关键词，过滤匹配的动作
    if (keyword) {
      const lowerKeyword = keyword.toLowerCase();
      const filteredActions = actions.filter(
        (action) =>
          action.title.toLowerCase().includes(lowerKeyword) ||
          action.description.toLowerCase().includes(lowerKeyword)
      );

      log.info(`过滤后返回 ${filteredActions.length} 个动作`);
      return filteredActions;
    }

    return actions;
  },

  /**
   * 执行插件动作
   * @param {Object} action 要执行的动作
   * @returns {Promise<any>} 动作执行结果
   */
  async executeAction(action) {
    log.info(`执行动作: ${action.id} (${action.title})`);

    try {
      switch (action.id) {
        case 'show_workspace':
          const workspace = await getVSCodeWorkspace();
          if (workspace) {
            return { message: `当前工作空间: ${workspace}` };
          } else {
            return { message: '未能获取到工作空间信息' };
          }

        default:
          const errorMsg = `未知的动作ID: ${action.id}`;
          log.error(errorMsg);
          throw new Error(errorMsg);
      }
    } catch (error) {
      log.error(`执行动作 ${action.id} 失败:`, error);
      throw error;
    }
  },
};

// 插件初始化输出
log.info(`IDE工作空间插件已加载: ${plugin.name} v${plugin.version}`);

// 导出插件
module.exports = plugin;

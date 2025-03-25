import { Logger } from './utils/logger';
import { VSCodeService } from './services/vscode';
import { CursorService } from './services/cursor';
import { Action, PluginContext, ActionResult } from './types';

const logger = new Logger('IDE工作空间');
const vscodeService = new VSCodeService();
const cursorService = new CursorService();

/**
 * IDE工作空间插件
 * 用于显示当前IDE的工作空间信息
 */
const plugin = {
  name: 'IDE工作空间',
  description: '显示当前IDE的工作空间信息',
  version: '1.0.0',
  author: 'Coffic',

  /**
   * 获取插件提供的动作列表
   */
  async getActions({
    keyword = '',
    overlaidApp = '',
  }: PluginContext): Promise<Action[]> {
    logger.info(`获取动作列表，关键词: "${keyword}", 应用: "${overlaidApp}"`);

    // 检查是否为支持的IDE
    const lowerApp = overlaidApp.toLowerCase();
    const isVSCode = lowerApp.includes('code') || lowerApp.includes('vscode');
    const isCursor = lowerApp.includes('cursor');

    if (!isVSCode && !isCursor) {
      logger.debug('不是支持的IDE，返回空列表');
      return [];
    }

    // 预先获取工作空间信息
    const workspace = await (isCursor
      ? cursorService.getWorkspace()
      : vscodeService.getWorkspace());

    const workspaceInfo = workspace
      ? `当前工作空间: ${workspace}`
      : `未能获取到 ${overlaidApp} 的工作空间信息`;

    // 创建动作列表
    const actions: Action[] = [
      {
        id: 'show_workspace',
        title: '显示工作空间',
        description: workspaceInfo,
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

      logger.info(`过滤后返回 ${filteredActions.length} 个动作`);
      return filteredActions;
    }

    return actions;
  },

  /**
   * 执行插件动作
   */
  async executeAction(action: Action): Promise<ActionResult> {
    logger.info(`执行动作: ${action.id} (${action.title})`);
    return { message: `完成` };
  },
};

// 插件初始化输出
logger.info(`IDE工作空间插件已加载: ${plugin.name} v${plugin.version}`);

// 导出插件
export = plugin;

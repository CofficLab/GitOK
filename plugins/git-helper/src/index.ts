import { Logger } from './utils/logger';
import { VSCodeService } from './services/vscode';
import { CursorService } from './services/cursor';
import { GitService } from './services/git';
import { WorkspaceCache } from './utils/workspace-cache';
import { Action, PluginContext, ActionResult, GitStatus } from './types';

const logger = new Logger('Git Helper');
const vscodeService = new VSCodeService();
const cursorService = new CursorService();

/**
 * Git Helper插件
 * 用于检查工作区Git状态，支持自动提交和推送的功能
 */
const plugin = {
  name: 'Git Helper',
  description: '检查当前IDE工作空间Git状态，提供自动提交和推送功能',
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

    // 保存当前应用ID到缓存
    await WorkspaceCache.saveCurrentApp(overlaidApp);

    // 预先获取工作空间信息
    const workspace = await (isCursor
      ? cursorService.getWorkspace()
      : vscodeService.getWorkspace());

    // 将工作区路径缓存到文件中
    if (workspace) {
      await WorkspaceCache.saveWorkspace(overlaidApp, workspace);
    }

    // 如果没有工作区，返回空列表
    if (!workspace) {
      logger.debug(`未能获取到 ${overlaidApp} 的工作空间信息，返回空列表`);
      return [];
    }

    // 检查Git状态
    let gitStatus: GitStatus = {
      isRepo: false,
      branch: '',
      changedFilesCount: 0,
      hasChanges: false,
      hasUnpushedCommits: false,
    };

    try {
      const gitService = new GitService(workspace);
      const isRepo = await gitService.isGitRepository();

      if (isRepo) {
        gitStatus = await gitService.getStatus();
      }
    } catch (error) {
      logger.error('获取Git状态失败:', error);
    }

    // 创建动作列表
    const actions: Action[] = [];

    // Git状态动作
    if (gitStatus.isRepo) {
      actions.push({
        id: 'git_status',
        title: 'Git状态',
        description: `分支: ${gitStatus.branch}, 变更文件: ${gitStatus.changedFilesCount}${
          gitStatus.hasUnpushedCommits ? ', 有未推送提交' : ''
        }`,
        icon: '📊',
      });

      // 如果有未提交的更改，添加提交并推送动作
      if (gitStatus.hasChanges) {
        actions.push({
          id: 'git_commit_push',
          title: '自动提交并推送更改',
          description: `将当前工作区的${gitStatus.changedFilesCount}个变更文件提交并推送到远程仓库`,
          icon: '🚀',
        });
      }
    }

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

    try {
      // 从缓存中获取工作区路径
      const workspace = WorkspaceCache.getWorkspace();

      if (!workspace) {
        const currentApp = WorkspaceCache.getCurrentApp();
        logger.error(`无法从缓存获取工作区路径，应用ID: ${currentApp}`);

        if (currentApp) {
          // 尝试重新获取工作区路径
          const isVSCode =
            currentApp.toLowerCase().includes('code') ||
            currentApp.toLowerCase().includes('vscode');
          const isCursor = currentApp.toLowerCase().includes('cursor');

          if (isVSCode || isCursor) {
            const freshWorkspace = await (isCursor
              ? cursorService.getWorkspace()
              : vscodeService.getWorkspace());

            if (freshWorkspace) {
              // 重新缓存工作区路径
              await WorkspaceCache.saveWorkspace(currentApp, freshWorkspace);

              // 继续执行动作
              return this.executeAction(action);
            }
          }
        }

        return { message: `无法获取工作区路径，请重新打开IDE` };
      }

      const gitService = new GitService(workspace);

      switch (action.id) {
        case 'git_status': {
          const isRepo = await gitService.isGitRepository();
          if (!isRepo) {
            return { message: `当前工作区不是Git仓库` };
          }

          const status = await gitService.getStatus();
          const changesDescription = await gitService.getChangesDescription();

          let message = `分支: ${status.branch}\n`;
          message += `变更文件数: ${status.changedFilesCount}\n`;

          if (status.hasChanges) {
            message += `变更详情: ${changesDescription}\n`;
          }

          if (status.hasUnpushedCommits) {
            message += `有未推送的提交\n`;
          }

          return { message };
        }

        case 'git_commit_push': {
          const isRepo = await gitService.isGitRepository();
          if (!isRepo) {
            return { message: `当前工作区不是Git仓库` };
          }

          const result = await gitService.commitAndPush();
          return { message: result.message };
        }

        default:
          return { message: `未知的动作: ${action.id}` };
      }
    } catch (error: any) {
      logger.error(`执行动作失败:`, error);
      return { message: `执行失败: ${error.message || '未知错误'}` };
    }
  },
};

// 插件初始化输出
logger.info(`Git Helper插件已加载: ${plugin.name} v${plugin.version}`);

// 导出插件
export = plugin;

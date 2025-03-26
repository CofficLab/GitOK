import { simpleGit, SimpleGit } from 'simple-git';
import { Logger } from '../utils/logger';
import { GitStatus } from '../types';
import path from 'path';
import fs from 'fs';

const logger = new Logger('GitService');

/**
 * Git服务
 * 用于检查仓库状态、自动提交和推送
 */
export class GitService {
  private git: SimpleGit | null = null;
  private workspacePath: string = '';

  /**
   * 初始化Git服务
   * @param workspacePath 工作区路径
   */
  constructor(workspacePath: string) {
    if (workspacePath) {
      // 清理路径，去除file://前缀
      const cleanPath = this.cleanWorkspacePath(workspacePath);
      this.workspacePath = cleanPath;

      try {
        this.git = simpleGit(cleanPath);
      } catch (error) {
        logger.error('初始化Git服务失败:', error);
      }
    }
  }

  /**
   * 清理工作区路径
   * 去除file://前缀和URL编码
   */
  private cleanWorkspacePath(workspace: string): string {
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
   * 检查是否是Git仓库
   */
  async isGitRepository(): Promise<boolean> {
    if (!this.git) return false;

    try {
      const gitDir = path.join(this.workspacePath, '.git');
      if (!fs.existsSync(gitDir)) {
        return false;
      }

      // 使用revparse检查是否是有效的Git仓库
      await this.git.revparse(['--is-inside-work-tree']);
      return true;
    } catch (error) {
      return false;
    }
  }

  /**
   * 获取Git仓库状态
   */
  async getStatus(): Promise<GitStatus> {
    const defaultStatus: GitStatus = {
      isRepo: false,
      branch: '',
      changedFilesCount: 0,
      hasChanges: false,
      hasUnpushedCommits: false,
    };

    if (!this.git) return defaultStatus;

    try {
      // 检查是否是Git仓库
      const isRepo = await this.isGitRepository();
      if (!isRepo) return defaultStatus;

      // 获取状态信息
      const status = await this.git.status();
      const branch = status.current || '';

      // 计算变更文件数量
      const changedFilesCount =
        status.created.length +
        status.deleted.length +
        status.modified.length +
        status.renamed.length +
        status.not_added.length;

      // 检查是否有未推送的提交
      const hasUnpushedCommits = await this.hasUnpushedCommits();

      return {
        isRepo,
        branch,
        changedFilesCount,
        hasChanges: changedFilesCount > 0,
        hasUnpushedCommits,
      };
    } catch (error) {
      logger.error('获取Git状态失败:', error);
      return defaultStatus;
    }
  }

  /**
   * 检查是否有未推送的提交
   */
  private async hasUnpushedCommits(): Promise<boolean> {
    if (!this.git) return false;

    try {
      // 获取当前分支
      const status = await this.git.status();
      const currentBranch = status.current || '';

      // 如果没有当前分支，返回false
      if (!currentBranch) return false;

      // 检查是否有远程分支
      const remotes = await this.git.getRemotes(true);
      if (remotes.length === 0) return false;

      // 获取默认远程名称
      const defaultRemote = remotes[0].name;

      // 检查是否存在对应的远程分支
      const remoteBranch = `${defaultRemote}/${currentBranch}`;
      try {
        await this.git.revparse(['--verify', `refs/remotes/${remoteBranch}`]);
      } catch (error) {
        // 远程分支不存在，认为有未推送的变更
        return true;
      }

      // 比较本地和远程分支
      const diff = await this.git.raw([
        'rev-list',
        '--count',
        `${remoteBranch}..${currentBranch}`,
      ]);
      const count = parseInt(diff.trim(), 10);

      return count > 0;
    } catch (error) {
      logger.error('检查未推送提交失败:', error);
      return false;
    }
  }

  /**
   * 获取未提交更改的描述信息
   */
  async getChangesDescription(): Promise<string> {
    if (!this.git) return '';

    try {
      const status = await this.git.status();
      let description = '';

      if (status.created.length > 0) {
        description += `新增: ${status.created.length}个文件, `;
      }

      if (status.modified.length > 0) {
        description += `修改: ${status.modified.length}个文件, `;
      }

      if (status.deleted.length > 0) {
        description += `删除: ${status.deleted.length}个文件, `;
      }

      if (status.renamed.length > 0) {
        description += `重命名: ${status.renamed.length}个文件, `;
      }

      if (status.not_added.length > 0) {
        description += `未跟踪: ${status.not_added.length}个文件, `;
      }

      // 去掉末尾的逗号和空格
      return description.replace(/, $/, '');
    } catch (error) {
      logger.error('获取变更描述失败:', error);
      return '';
    }
  }

  /**
   * 自动提交并推送
   */
  async commitAndPush(): Promise<{ success: boolean; message: string }> {
    if (!this.git) {
      return { success: false, message: 'Git服务未初始化' };
    }

    try {
      // 检查是否是Git仓库
      const isRepo = await this.isGitRepository();
      if (!isRepo) {
        return { success: false, message: '当前目录不是Git仓库' };
      }

      // 检查状态
      const status = await this.git.status();

      // 计算变更文件数量
      const changedFilesCount =
        status.created.length +
        status.deleted.length +
        status.modified.length +
        status.renamed.length +
        status.not_added.length;

      if (changedFilesCount === 0) {
        return {
          success: false,
          message: '没有需要提交的更改',
        };
      }

      // 构造提交信息
      const changesDescription = await this.getChangesDescription();
      const commitMessage = `自动提交: ${changesDescription} [GitOK]`;

      // 添加所有更改
      await this.git.add('.');

      // 提交更改
      await this.git.commit(commitMessage);

      // 检查是否有远程仓库
      const remotes = await this.git.getRemotes(true);
      if (remotes.length === 0) {
        return {
          success: true,
          message: '已成功提交更改，但未找到远程仓库，无法推送',
        };
      }

      // 获取当前分支
      const currentBranch = status.current || '';

      // 如果没有当前分支，不推送
      if (!currentBranch) {
        return {
          success: true,
          message: '已成功提交更改，但未能获取当前分支，无法推送',
        };
      }

      // 推送到远程仓库
      await this.git.push('origin', currentBranch);

      return {
        success: true,
        message: `已成功提交并推送更改: ${commitMessage}`,
      };
    } catch (error: any) {
      logger.error('提交并推送失败:', error);
      return {
        success: false,
        message: `提交并推送失败: ${error.message || '未知错误'}`,
      };
    }
  }
}

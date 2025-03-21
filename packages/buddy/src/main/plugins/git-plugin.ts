/**
 * Git插件
 * 提供Git相关命令和操作
 */
import { Plugin, PluginAction } from './types';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

class GitPlugin implements Plugin {
  id = 'git-plugin';
  name = 'Git 插件';
  description = '提供Git版本控制相关功能';
  version = '1.0.0';

  private actions: PluginAction[] = [
    {
      id: 'git-commit',
      title: 'Git: 提交更改',
      description: '提交当前仓库的所有更改',
      icon: 'i-mdi-source-commit',
      plugin: this.id,
    },
    {
      id: 'git-pull',
      title: 'Git: 拉取更新',
      description: '从远程仓库拉取最新代码',
      icon: 'i-mdi-source-pull',
      plugin: this.id,
    },
    {
      id: 'git-push',
      title: 'Git: 推送更改',
      description: '将本地提交推送到远程仓库',
      icon: 'i-mdi-source-repository-push',
      plugin: this.id,
    },
    {
      id: 'git-branch',
      title: 'Git: 创建分支',
      description: '创建新的功能分支',
      icon: 'i-mdi-source-branch-plus',
      plugin: this.id,
    },
    {
      id: 'git-merge',
      title: 'Git: 合并分支',
      description: '合并指定分支到当前分支',
      icon: 'i-mdi-source-merge',
      plugin: this.id,
    },
    {
      id: 'git-checkout',
      title: 'Git: 切换分支',
      description: '切换到指定的分支',
      icon: 'i-mdi-source-branch',
      plugin: this.id,
    },
  ];

  getActions(): PluginAction[] {
    return this.actions;
  }

  async executeAction(actionId: string): Promise<any> {
    switch (actionId) {
      case 'git-commit':
        return this.commit();
      case 'git-pull':
        return this.pull();
      case 'git-push':
        return this.push();
      case 'git-branch':
        return this.createBranch();
      case 'git-merge':
        return this.mergeBranch();
      case 'git-checkout':
        return this.checkout();
      default:
        throw new Error(`Git插件: 未知动作 ${actionId}`);
    }
  }

  // Git命令实现
  private async commit(message = 'Auto commit from GitOK'): Promise<any> {
    console.log('执行Git提交');
    try {
      await execAsync('git add .');
      const { stdout } = await execAsync(`git commit -m "${message}"`);
      return { success: true, message: stdout };
    } catch (error) {
      console.error('Git提交失败:', error);
      throw error;
    }
  }

  private async pull(): Promise<any> {
    console.log('执行Git拉取');
    try {
      const { stdout } = await execAsync('git pull');
      return { success: true, message: stdout };
    } catch (error) {
      console.error('Git拉取失败:', error);
      throw error;
    }
  }

  private async push(): Promise<any> {
    console.log('执行Git推送');
    try {
      const { stdout } = await execAsync('git push');
      return { success: true, message: stdout };
    } catch (error) {
      console.error('Git推送失败:', error);
      throw error;
    }
  }

  private async createBranch(branchName = 'feature/new-branch'): Promise<any> {
    console.log('执行Git创建分支');
    try {
      const { stdout } = await execAsync(`git checkout -b ${branchName}`);
      return { success: true, message: stdout };
    } catch (error) {
      console.error('Git创建分支失败:', error);
      throw error;
    }
  }

  private async mergeBranch(branchName = 'main'): Promise<any> {
    console.log('执行Git合并分支');
    try {
      const { stdout } = await execAsync(`git merge ${branchName}`);
      return { success: true, message: stdout };
    } catch (error) {
      console.error('Git合并分支失败:', error);
      throw error;
    }
  }

  private async checkout(branchName = 'main'): Promise<any> {
    console.log('执行Git切换分支');
    try {
      const { stdout } = await execAsync(`git checkout ${branchName}`);
      return { success: true, message: stdout };
    } catch (error) {
      console.error('Git切换分支失败:', error);
      throw error;
    }
  }
}

// 导出Git插件实例
export const gitPlugin = new GitPlugin();

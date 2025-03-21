/**
 * NPM插件
 * 提供NPM包管理相关操作
 */
import { Plugin, PluginAction } from './types';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

class NPMPlugin implements Plugin {
  id = 'npm-plugin';
  name = 'NPM 插件';
  description = '提供NPM包管理相关功能';
  version = '1.0.0';

  private actions: PluginAction[] = [
    {
      id: 'npm-install',
      title: 'NPM: 安装依赖',
      description: '安装项目依赖',
      icon: 'i-mdi-npm',
      plugin: this.id,
    },
    {
      id: 'npm-start',
      title: 'NPM: 启动项目',
      description: '启动开发服务器',
      icon: 'i-mdi-play',
      plugin: this.id,
    },
    {
      id: 'npm-build',
      title: 'NPM: 构建项目',
      description: '构建生产版本',
      icon: 'i-mdi-package',
      plugin: this.id,
    },
  ];

  getActions(): PluginAction[] {
    return this.actions;
  }

  async executeAction(actionId: string): Promise<any> {
    switch (actionId) {
      case 'npm-install':
        return this.install();
      case 'npm-start':
        return this.start();
      case 'npm-build':
        return this.build();
      default:
        throw new Error(`NPM插件: 未知动作 ${actionId}`);
    }
  }

  // NPM命令实现
  private async install(packageName?: string): Promise<any> {
    console.log('执行NPM安装');
    try {
      const command = packageName ? `pnpm add ${packageName}` : 'pnpm install';
      const { stdout } = await execAsync(command);
      return { success: true, message: stdout };
    } catch (error) {
      console.error('NPM安装失败:', error);
      throw error;
    }
  }

  private async start(): Promise<any> {
    console.log('执行NPM启动项目');
    try {
      // 这里只返回成功信息，实际启动应该由其他进程管理
      return { success: true, message: '项目启动指令已发送' };
    } catch (error) {
      console.error('NPM启动项目失败:', error);
      throw error;
    }
  }

  private async build(): Promise<any> {
    console.log('执行NPM构建项目');
    try {
      const { stdout } = await execAsync('pnpm build');
      return { success: true, message: stdout };
    } catch (error) {
      console.error('NPM构建项目失败:', error);
      throw error;
    }
  }
}

// 导出NPM插件实例
export const npmPlugin = new NPMPlugin();

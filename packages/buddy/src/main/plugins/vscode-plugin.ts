/**
 * VSCode插件
 * 提供与VSCode编辑器相关的操作
 */
import { Plugin, PluginAction } from './types';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

class VSCodePlugin implements Plugin {
  id = 'vscode-plugin';
  name = 'VSCode 插件';
  description = '提供VS Code编辑器相关功能';
  version = '1.0.0';

  private actions: PluginAction[] = [
    {
      id: 'vscode-open',
      title: 'VSCode: 打开项目',
      description: '在VS Code中打开当前项目',
      icon: 'i-mdi-microsoft-visual-studio-code',
      plugin: this.id,
    },
  ];

  getActions(): PluginAction[] {
    return this.actions;
  }

  async executeAction(actionId: string): Promise<any> {
    switch (actionId) {
      case 'vscode-open':
        return this.openInVSCode();
      default:
        throw new Error(`VSCode插件: 未知动作 ${actionId}`);
    }
  }

  // 在VSCode中打开当前项目
  private async openInVSCode(projectPath?: string): Promise<any> {
    console.log('在VSCode中打开项目');
    try {
      // 如果没有指定路径，使用当前目录
      const targetPath = projectPath || process.cwd();

      // 使用code命令打开VSCode
      const { stdout } = await execAsync(`code "${targetPath}"`);
      return {
        success: true,
        message: '已在VS Code中打开项目',
        path: targetPath,
      };
    } catch (error) {
      console.error('打开VS Code失败:', error);
      throw error;
    }
  }
}

// 导出VSCode插件实例
export const vscodePlugin = new VSCodePlugin();

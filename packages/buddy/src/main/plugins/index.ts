/**
 * 插件系统导出
 */
import { ipcMain, dialog } from 'electron';
import { app } from 'electron';
import path from 'path';
import { pluginManager } from './PluginManager';
import { pluginInstaller } from './PluginInstaller';
import { BrowserWindow } from 'electron';

// 定义IPC通道名称
const IPC_CHANNELS = {
  GET_PLUGINS: 'plugin:get-installed',
  INSTALL_PLUGIN: 'plugin:install',
  UNINSTALL_PLUGIN: 'plugin:uninstall',
  OPEN_PLUGIN_FILE: 'plugin:open-file',
  INSTALL_SAMPLE_PLUGIN: 'plugin:install-sample',
  GET_PLUGIN_VIEWS: 'plugins:getViews',
  GET_ALL_PLUGINS: 'plugins:getAllPlugins',
  ACTIVATE_PLUGIN: 'plugins:activatePlugin',
  DEACTIVATE_PLUGIN: 'plugins:deactivatePlugin',
};

/**
 * 初始化插件系统
 */
export function initPluginSystem() {
  console.log('🔌 初始化插件系统...');

  // 监听获取插件列表请求
  ipcMain.handle(IPC_CHANNELS.GET_PLUGINS, () => {
    console.log('📋 获取已安装插件列表');
    const plugins = pluginManager.getInstalledPlugins();
    console.log(`📋 已找到 ${Object.keys(plugins).length} 个已安装插件`);
    return plugins;
  });

  // 监听安装插件请求
  ipcMain.handle(IPC_CHANNELS.INSTALL_PLUGIN, async (_, pluginPath: string) => {
    console.log(`📥 开始安装插件: ${pluginPath}`);
    try {
      // 如果是URL，先下载
      if (pluginPath.startsWith('http')) {
        console.log(`🌐 从URL下载插件: ${pluginPath}`);
        pluginPath = await pluginInstaller.downloadPlugin(pluginPath);
        console.log(`🌐 插件下载完成: ${pluginPath}`);
      }

      // 安装插件
      console.log(`📦 解析插件文件: ${pluginPath}`);
      const pluginId = await pluginInstaller.installFromFile(pluginPath);
      console.log(`🔍 解析到插件ID: ${pluginId}`);

      // 更新插件注册表
      console.log(`📝 更新插件注册表: ${pluginId}`);
      await pluginManager.installPlugin(pluginPath);
      console.log(`✅ 插件安装完成: ${pluginId}`);

      // 通知渲染进程插件已安装
      BrowserWindow.getAllWindows().forEach((window) => {
        window.webContents.send('plugin:installed');
      });

      return { success: true, pluginId };
    } catch (error: any) {
      console.error('❌ 安装插件失败:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : '未知错误',
      };
    }
  });

  // 安装示例插件
  ipcMain.handle(IPC_CHANNELS.INSTALL_SAMPLE_PLUGIN, async () => {
    console.log('🧩 开始安装示例插件');
    try {
      // 查找项目根目录中的示例插件
      const appPath = app.getAppPath();
      const projectRoot = path.dirname(path.dirname(appPath)); // 通常是packages的上一级
      const samplePluginPath = path.join(
        projectRoot,
        'packages',
        'simple-plugin',
        'dist',
        'simple-plugin.buddy'
      );
      console.log(`🔍 查找示例插件路径: ${samplePluginPath}`);

      // 检查示例插件文件是否存在
      const fs = require('fs');
      if (!fs.existsSync(samplePluginPath)) {
        console.warn(`⚠️ 示例插件文件不存在: ${samplePluginPath}`);
        return {
          success: false,
          error:
            '示例插件文件不存在，请先构建示例插件：cd packages/simple-plugin && pnpm build && pnpm bundle',
        };
      }
      console.log(`📂 找到示例插件文件: ${samplePluginPath}`);

      // 安装插件
      console.log('📦 开始解析示例插件文件');
      const pluginId = await pluginInstaller.installFromFile(samplePluginPath);
      console.log(`🔍 解析到示例插件ID: ${pluginId}`);

      // 更新插件注册表
      console.log(`📝 更新插件注册表: ${pluginId}`);
      await pluginManager.installPlugin(samplePluginPath);
      console.log(`✅ 示例插件安装完成: ${pluginId}`);

      // 通知渲染进程插件已安装
      BrowserWindow.getAllWindows().forEach((window) => {
        window.webContents.send('plugin:installed');
      });

      return { success: true, pluginId };
    } catch (error) {
      console.error('❌ 安装示例插件失败:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : '未知错误',
      };
    }
  });

  // 监听卸载插件请求
  ipcMain.handle(IPC_CHANNELS.UNINSTALL_PLUGIN, (_, pluginId: string) => {
    console.log(`🗑️ 开始卸载插件: ${pluginId}`);
    try {
      const success = pluginManager.uninstallPlugin(pluginId);
      if (success) {
        console.log(`✅ 插件卸载成功: ${pluginId}`);
        // 通知渲染进程插件已卸载
        BrowserWindow.getAllWindows().forEach((window) => {
          window.webContents.send('plugin:installed');
        });
      } else {
        console.warn(`⚠️ 插件卸载失败: ${pluginId}`);
      }
      return { success };
    } catch (error) {
      console.error(`❌ 卸载插件出错: ${pluginId}`, error);
      return { success: false };
    }
  });

  // 监听打开插件文件请求
  ipcMain.handle(IPC_CHANNELS.OPEN_PLUGIN_FILE, async () => {
    console.log('📂 打开插件文件选择对话框');
    try {
      const result = await dialog.showOpenDialog({
        properties: ['openFile'],
        filters: [{ name: 'Buddy插件', extensions: ['buddy', 'zip'] }],
      });

      if (result.canceled) {
        console.log('🚫 用户取消了文件选择');
        return { success: false, canceled: true };
      }

      if (result.filePaths.length === 0) {
        console.log('⚠️ 未选择任何文件');
        return { success: false, canceled: true };
      }

      console.log(`📄 用户选择了文件: ${result.filePaths[0]}`);
      return { success: true, filePath: result.filePaths[0] };
    } catch (error) {
      console.error('❌ 打开文件对话框失败:', error);
      return { success: false, error: '打开文件对话框失败' };
    }
  });

  // 获取插件视图
  ipcMain.handle(IPC_CHANNELS.GET_PLUGIN_VIEWS, () => {
    console.log('🔍 获取插件视图');

    // 获取已安装的插件列表
    const installedPlugins = pluginManager.getInstalledPlugins();
    const views: any[] = [];

    // 为已安装的simple-plugin添加视图
    if (installedPlugins['simple-plugin']) {
      console.log('📌 发现simple-plugin，添加其视图');
      views.push({
        id: 'simple-plugin-view',
        name: '示例插件视图',
        // 修改路径，使用相对路径但不包含components
        absolutePath: './Versions.vue',
        icon: 'i-mdi-puzzle-outline',
        pluginId: 'simple-plugin',
      });
    }

    // 如果没有找到任何插件视图，添加一个示例视图用于测试
    if (views.length === 0) {
      console.log('📌 未找到已安装插件视图，返回测试视图');
      views.push({
        id: 'example-view',
        name: '示例视图',
        absolutePath: './Versions.vue',
        icon: 'i-mdi-view-dashboard',
      });
    }

    console.log(`📋 返回 ${views.length} 个插件视图:`, views);
    return views;
  });

  // 获取所有插件
  ipcMain.handle(IPC_CHANNELS.GET_ALL_PLUGINS, () => {
    console.log('📋 获取所有插件信息');
    const plugins = pluginManager.getInstalledPlugins();
    console.log(`📋 返回 ${Object.keys(plugins).length} 个插件信息`);
    return plugins;
  });

  // 激活插件
  ipcMain.handle(IPC_CHANNELS.ACTIVATE_PLUGIN, (_, pluginId: string) => {
    console.log(`🔌 激活插件: ${pluginId}`);
    // 暂时返回true，后续实现插件激活功能
    return true;
  });

  // 停用插件
  ipcMain.handle(IPC_CHANNELS.DEACTIVATE_PLUGIN, (_, pluginId: string) => {
    console.log(`🔌 停用插件: ${pluginId}`);
    // 暂时返回true，后续实现插件停用功能
    return true;
  });

  console.log('✅ 插件系统初始化完成');
}

// 导出插件系统接口
export { pluginManager, pluginInstaller };

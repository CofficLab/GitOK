import { SuperPlugin } from '@/types/super_plugin';
import { defineStore } from 'pinia';
import { logger } from '../utils/logger';
import { pluginsAPI } from '../api/plugins-api';

interface MarketState {
  userPluginDirectory: string;
  error: string;
  userPlugins: any[];
  devPlugins: any[];
  remotePlugins: any[];
  loadingPlugins: boolean;
  loadingRemotePlugins: boolean;
  downloadingPlugins: Set<string>;
  uninstallingPlugins: Set<string>;
}

export const useMarketStore = defineStore('market', {
  state: (): MarketState => ({
    userPluginDirectory: '',
    error: '',
    userPlugins: [],
    devPlugins: [],
    remotePlugins: [],
    loadingPlugins: false,
    loadingRemotePlugins: false,
    downloadingPlugins: new Set<string>(),
    uninstallingPlugins: new Set<string>(),
  }),

  actions: {
    // 加载开发插件列表
    async loadDevPlugins() {
      this.loadingPlugins = true;

      try {
        const response = await pluginsAPI.getDevPlugins();
        if (response.success && response.data) {
          this.devPlugins = response.data || [];
        } else {
          this.error = `加载插件列表失败: ${response.error || '未知错误'}`;
          console.error('加载插件列表失败', response);
        }
      } catch (err) {
        const errorMsg = err instanceof Error ? err.message : String(err);
        this.error = `加载插件列表失败: ${errorMsg}`;
        console.error('Failed to load plugins:', err);
      } finally {
        this.loadingPlugins = false;
      }
    },

    // 加载用户插件列表
    async loadUserPlugins() {
      this.loadingPlugins = true;

      try {
        const response = await pluginsAPI.getUserPlugins();
        if (response.success && response.data) {
          this.userPlugins = response.data || [];
        } else {
          this.error = `加载插件列表失败: ${response.error || '未知错误'}`;
          console.error('加载插件列表失败', response);
        }
      } catch (err) {
        const errorMsg = err instanceof Error ? err.message : String(err);
        this.error = `加载插件列表失败: ${errorMsg}`;
        console.error('Failed to load plugins:', err);
      } finally {
        this.loadingPlugins = false;
      }
    },

    // 更新用户插件目录
    async updateUserPluginDirectory() {
      logger.info('🍋 updateUserPluginDirectory');
      try {
        const response = (await pluginsAPI.getUserPluginDirectory())

        logger.info('🍋 getUserPluginDirectory response', response);

        if (response.success && response.data) {
          this.userPluginDirectory = response.data;
        } else {
          this.error = `加载目录信息失败: ${response.error || '未知错误'}`;
          console.error('加载目录信息失败', response);
          console.error(response);
        }
      } catch (error) {
        const errorMsg = error instanceof Error ? error.message : String(error);
        this.error = `加载目录信息失败: ${errorMsg}`;
        console.error('加载目录信息失败', error);
      }
    },

    // 下载插件
    async downloadPlugin(plugin: SuperPlugin) {
      if (this.downloadingPlugins.has(plugin.id)) {
        return; // 避免重复下载
      }

      try {
        // 设置下载中状态
        this.downloadingPlugins.add(plugin.id);

        // 只传递必要的属性，避免克隆问题
        const pluginData = {
          id: plugin.id,
          name: plugin.name,
          version: plugin.version,
          description: plugin.description,
          author: plugin.author,
          type: plugin.type,
          path: plugin.path,
          npmPackage: plugin.npmPackage,
        };

        // 调用主进程下载插件
        const response = (await pluginsAPI.downloadPlugin(pluginData)) as {
          success: boolean;
          data?: boolean;
          error?: string;
        };

        // 更新下载状态
        this.downloadingPlugins.delete(plugin.id);

        if (response.success) {
          // 刷新插件列表
          await this.loadUserPlugins();
        } else {
          console.error(
            `插件 "${plugin.name}" 下载失败: ${response.error || '未知错误'}`
          );
        }
      } catch (error) {
        this.downloadingPlugins.delete(plugin.id);
        const errorMsg = error instanceof Error ? error.message : String(error);

        // 同时在全局显示错误信息，方便用户复制
        console.error(`插件 "${plugin.name}" 下载失败: ${errorMsg}`);
      }
    },

    // 卸载插件
    async uninstallPlugin(plugin: SuperPlugin) {
      if (this.uninstallingPlugins.has(plugin.id)) {
        return; // 避免重复操作
      }

      try {
        // 设置卸载中状态
        this.uninstallingPlugins.add(plugin.id);

        // 调用主进程卸载插件
        const response = (await pluginsAPI.uninstallPlugin(plugin.id)) as {
          success: boolean;
          data?: boolean;
          error?: string;
        };

        // 更新卸载状态
        this.uninstallingPlugins.delete(plugin.id);

        if (response.success) {
          // 刷新插件列表
          await this.loadUserPlugins();
        } else {
          // 显示全局错误信息
          console.error(
            `插件 "${plugin.name}" 卸载失败: ${response.error || '未知错误'}`
          );
        }
      } catch (error) {
        this.uninstallingPlugins.delete(plugin.id);
        const errorMsg = error instanceof Error ? error.message : String(error);

        // 显示全局错误信息
        console.error(`插件 "${plugin.name}" 卸载失败: ${errorMsg}`);
      }
    },

    // 加载远程插件列表
    async loadRemotePlugins() {
      logger.info('🐶 loadRemotePlugins');
      if (this.loadingRemotePlugins) return;

      this.loadingRemotePlugins = true;
      try {
        // 调用主进程方法获取远程插件列表
        const response = await pluginsAPI.getRemotePlugins();

        console.log('🍋 get remote plugins response', response);

        if (response.success) {
          this.remotePlugins = response.data || [];
        } else {
          this.error = `加载远程插件列表失败: ${response.error || '未知错误'}`;
          console.error('加载远程插件列表失败', response);
        }
      } catch (err) {
        const errorMsg = err instanceof Error ? err.message : String(err);
        this.error = `加载远程插件列表失败: ${errorMsg}`;
        console.error('Failed to load remote plugins:', err);
      } finally {
        this.loadingRemotePlugins = false;
      }
    },
  },
});

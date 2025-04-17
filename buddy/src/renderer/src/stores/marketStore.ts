
import { defineStore } from 'pinia';
import { logger } from '../utils/logger';
import { marketIpc } from '../ipc/market-ipc';
import { SuperPlugin } from '@coffic/buddy-types';
import { SendablePlugin } from '@/types/sendable-plugin';

const verbose = false;

interface MarketState {
    userPluginDirectory: string;
    error: string;
    userPlugins: SendablePlugin[];
    devPlugins: SendablePlugin[];
    pluginsWithPage: SendablePlugin[];
    remotePlugins: SendablePlugin[];
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
        pluginsWithPage: [],
        remotePlugins: [],
        loadingPlugins: false,
        loadingRemotePlugins: false,
        downloadingPlugins: new Set<string>(),
        uninstallingPlugins: new Set<string>(),
    }),

    actions: {
        onMounted() {
            this.updateUserPluginDirectory()
            this.loadUserPlugins()
            this.loadDevPlugins()
            this.loadRemotePlugins()
        },

        onUnmounted() {

        },

        // 加载开发插件列表
        async loadDevPlugins() {
            this.loadingPlugins = true;

            try {
                const response = await marketIpc.getDevPlugins();

                if (verbose) {
                    logger.info('get dev plugins, with count', response.data?.length);
                }
                if (response.success && response.data) {
                    this.devPlugins = response.data || [];
                } else {
                    this.devPlugins = [];
                    this.error = `加载插件列表失败: ${response.error || '未知错误'}`;
                    logger.error('加载插件列表失败', response);
                }
            } catch (err) {
                const errorMsg = err instanceof Error ? err.message : String(err);
                this.error = `加载插件列表失败: ${errorMsg}`;
                console.error('Failed to load plugins:', err);
            } finally {
                this.loadingPlugins = false;
                this.pluginsWithPage = this.devPlugins.filter(plugin => plugin.hasPage);
            }
        },

        // 加载用户插件列表
        async loadUserPlugins() {
            this.loadingPlugins = true;

            try {
                const response = await marketIpc.getUserPlugins();
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
            try {
                const response = (await marketIpc.getUserPluginDirectory())

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
        async downloadPlugin(plugin: SendablePlugin) {
            if (this.downloadingPlugins.has(plugin.id)) {
                return; // 避免重复下载
            }

            try {
                // 设置下载中状态
                this.downloadingPlugins.add(plugin.id);

                // 调用主进程下载插件
                const response = (await marketIpc.downloadPlugin(plugin.id));

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
                const response = (await marketIpc.uninstallPlugin(plugin.id));

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
        async loadRemotePlugins(): Promise<void> {
            if (this.loadingRemotePlugins) return;

            this.loadingRemotePlugins = true;

            try {
                // 调用主进程方法获取远程插件列表
                const response = await marketIpc.getRemotePlugins();

                if (response.success) {
                    this.remotePlugins = response.data || [];
                } else {
                    throw new Error(response.error);
                }
            } catch (err) {
                throw err;
            } finally {
                this.loadingRemotePlugins = false;
            }
        },
    },
});

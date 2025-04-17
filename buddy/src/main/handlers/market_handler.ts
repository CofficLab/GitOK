
import { IpcRoute } from '../provider/RouterService.js';
import { logger } from '../managers/LogManager.js';
import { userPluginDB } from '../db/UserPackageDB.js';
import { remotePluginDB } from '../db/RemoteDB.js';
import { packageDownloaderDB as Downloader } from '../service/Downloader.js';
import * as fs from 'fs';
import * as path from 'path';
import { devPluginDB } from '../db/DevPluginDB.js';
import { IPC_METHODS, IpcResponse } from '@coffic/buddy-types';
import { SendablePlugin } from '@/types/sendable-plugin.js';

/**
 * 插件商店相关的IPC路由配置
 */
export const marketRoutes: IpcRoute[] = [
    {
        channel: IPC_METHODS.Plugin_Is_Installed,
        handler: async (pluginId: string): Promise<IpcResponse<boolean>> => {
            const has = await userPluginDB.has(pluginId);
            return { success: true, data: has };
        },
    },
    {
        channel: IPC_METHODS.GET_USER_PLUGINS,
        handler: async (): Promise<IpcResponse<SendablePlugin[]>> => {
            try {
                const plugins = await userPluginDB.getAllPlugins();
                return { success: true, data: plugins };
            } catch (error) {
                const errorMessage =
                    error instanceof Error ? error.message : String(error);
                logger.error('获取插件列表失败', { error: errorMessage });
                return { success: false, error: errorMessage };
            }
        },
    },
    {
        channel: IPC_METHODS.GET_DEV_PLUGINS,
        handler: async (): Promise<IpcResponse<SendablePlugin[]>> => {
            try {
                const plugins = await devPluginDB.getAllPlugins();
                return { success: true, data: plugins };
            } catch (error) {
                const errorMessage =
                    error instanceof Error ? error.message : String(error);
                logger.error('获取开发插件列表失败', { error: errorMessage });
                return { success: false, error: errorMessage };
            }
        }
    },
    {
        channel: IPC_METHODS.GET_REMOTE_PLUGINS,
        handler: async (): Promise<IpcResponse<SendablePlugin[]>> => {
            try {
                const plugins = await remotePluginDB.getPlugins();
                return { success: true, data: plugins };
            } catch (error) {
                const errorMessage =
                    error instanceof Error ? error.message : String(error);
                logger.error('获取远程插件列表失败', { error: errorMessage });
                return { success: false, error: errorMessage };
            }
        },
    },
    {
        channel: IPC_METHODS.DOWNLOAD_PLUGIN,
        handler: async (_, pluginId: string): Promise<IpcResponse<boolean>> => {
            try {
                const userPluginDir = userPluginDB.getRootDir();
                if (!fs.existsSync(userPluginDir)) {
                    fs.mkdirSync(userPluginDir, { recursive: true });
                }

                const safePluginId = pluginId.replace(/[@/]/g, '-');
                const pluginDir = path.join(userPluginDir, safePluginId);
                if (!fs.existsSync(pluginDir)) {
                    fs.mkdirSync(pluginDir, { recursive: true });
                }

                logger.info(`开始下载插件`, pluginId);

                try {
                    await Downloader.downloadAndExtractPackage(
                        pluginId,
                        pluginDir
                    );
                    await userPluginDB.getAllPlugins();
                    logger.info(`${pluginId} installed`);
                    return { success: true, data: true };
                } catch (error) {
                    const errorMessage =
                        error instanceof Error ? error.message : String(error);
                    logger.error('下载插件过程中出错', {
                        error: errorMessage,
                        pluginName: pluginId,
                        pluginId: pluginId,
                        npmPackage: pluginId,
                    });
                    return { success: false, error: errorMessage };
                }
            } catch (error) {
                const errorMessage =
                    error instanceof Error ? error.message : String(error);
                logger.error('下载插件初始化失败', {
                    error: errorMessage,
                    pluginName: pluginId,
                    pluginId: pluginId,
                    npmPackage: pluginId,
                });
                return { success: false, error: errorMessage };
            }
        },
    },
    {
        channel: IPC_METHODS.GET_PLUGIN_DIRECTORIES,
        handler: (): IpcResponse<string> => {
            return {
                success: true,
                data: userPluginDB.getRootDir(),
            };
        },
    },
    {
        channel: IPC_METHODS.UNINSTALL_PLUGIN,
        handler: async (_, pluginId: string): Promise<IpcResponse<boolean>> => {
            try {
                logger.info(`准备卸载插件: ${pluginId}`);
                const plugin = await userPluginDB.find(pluginId);
                if (!plugin) {
                    logger.error(`卸载插件失败: 找不到插件 ${pluginId}`);
                    return {
                        success: false,
                        error: `找不到插件: ${pluginId}`,
                    };
                }

                if (plugin.type !== 'user') {
                    logger.error(`卸载插件失败: 无法卸载开发中的插件 ${pluginId}`);
                    return {
                        success: false,
                        error: '无法卸载开发中的插件',
                    };
                }

                const pluginPath = plugin.path;
                if (!pluginPath || !fs.existsSync(pluginPath)) {
                    logger.error(`卸载插件失败: 插件目录不存在 ${pluginPath}`);
                    return {
                        success: false,
                        error: '插件目录不存在',
                    };
                }

                logger.info(`删除插件目录: ${pluginPath}`);
                fs.rmdirSync(pluginPath, { recursive: true });
                logger.info(`插件 ${pluginId} 卸载成功`);
                return { success: true, data: true };
            } catch (error) {
                const errorMessage =
                    error instanceof Error ? error.message : String(error);
                logger.error(`卸载插件失败: ${errorMessage}`, { pluginId });
                return {
                    success: false,
                    error: `卸载插件失败: ${errorMessage}`,
                };
            }
        },
    },
];

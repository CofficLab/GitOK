import * as fs from 'fs';
import * as path from 'path';
import { logger } from './LogManager.js';
import { userPluginDB } from '../db/UserPackageDB.js';
import { packageDownloaderDB } from '../service/Downloader.js';

/**
 * 插件市场管理器
 * 负责处理插件的下载、安装、卸载等操作
 */
export class MarketManager {
    /**
     * 下载并安装插件
     * @param pluginId 插件ID
     * @returns 安装是否成功
     */
    public async downloadAndInstallPlugin(pluginId: string): Promise<void> {
        try {
            const userPluginDir = userPluginDB.getRootDir();
            if (!fs.existsSync(userPluginDir)) {
                fs.mkdirSync(userPluginDir, { recursive: true });
            }

            // 处理插件ID中的特殊字符，确保文件路径安全
            const safePluginId = pluginId.replace(/[@/]/g, '-');
            const pluginDir = path.join(userPluginDir, safePluginId);
            if (!fs.existsSync(pluginDir)) {
                fs.mkdirSync(pluginDir, { recursive: true });
            }

            logger.info(`开始下载插件`, pluginId);

            await packageDownloaderDB.downloadAndExtractPackage(pluginId, pluginDir);
            await userPluginDB.getAllPlugins();
        } catch (error) {
            const errorMessage = error instanceof Error ? error.message : String(error);
            logger.error('下载插件失败', {
                error: errorMessage,
                pluginId: pluginId,
            });
            throw error;
        }
    }

    /**
     * 卸载插件
     * @param pluginId 插件ID
     * @returns 卸载是否成功
     */
    public async uninstallPlugin(pluginId: string): Promise<void> {
        try {
            logger.info(`准备卸载插件: ${pluginId}`);

            if (!pluginId) {
                throw new Error('插件ID不能为空');
            }

            const plugin = await userPluginDB.find(pluginId);

            if (!plugin) {
                throw new Error(`找不到插件: ${pluginId}`);
            }

            plugin.uninstall();
        } catch (error) {
            const errorMessage = error instanceof Error ? error.message : String(error);
            logger.error(`卸载插件失败: ${errorMessage}`, { pluginId });
            throw error;
        }
    }
}

// 导出单例实例
export const marketManager = new MarketManager(); 
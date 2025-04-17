import { IpcRoute } from '@/main/provider/RouterService.js';
import { userPluginDB } from '@/main/db/UserPackageDB.js';
import { remotePluginDB } from '@/main/db/RemoteDB.js';
import { devPluginDB } from '@/main/db/DevPluginDB.js';
import { IPC_METHODS } from '@coffic/buddy-types';
import { SendablePlugin } from '@/types/sendable-plugin.js';
import { marketManager } from '@/main/managers/MarketManager.js';

export const marketHandler: IpcRoute[] = [
    {
        channel: IPC_METHODS.Plugin_Is_Installed,
        handler: async (pluginId: string): Promise<boolean> => {
            return await userPluginDB.has(pluginId);
        },
    },
    {
        channel: IPC_METHODS.GET_USER_PLUGINS,
        handler: async (): Promise<SendablePlugin[]> => {
            return await userPluginDB.getAllPlugins();
        },
    },
    {
        channel: IPC_METHODS.GET_DEV_PLUGINS,
        handler: async (): Promise<SendablePlugin[]> => {
            return await devPluginDB.getAllPlugins();
        }
    },
    {
        channel: IPC_METHODS.GET_REMOTE_PLUGINS,
        handler: async (): Promise<SendablePlugin[]> => {
            return await remotePluginDB.getPlugins();
        },
    },
    {
        channel: IPC_METHODS.DOWNLOAD_PLUGIN,
        handler: async (_, pluginId: string): Promise<boolean> => {
            return await marketManager.downloadAndInstallPlugin(pluginId);
        },
    },
    {
        channel: IPC_METHODS.GET_PLUGIN_DIRECTORIES,
        handler: (): string => {
            return userPluginDB.getRootDir();
        },
    },
    {
        channel: IPC_METHODS.UNINSTALL_PLUGIN,
        handler: async (_, pluginId: string): Promise<boolean> => {
            return await marketManager.uninstallPlugin(pluginId);
        },
    },
];


import { SendablePlugin } from "@/types/sendable-plugin";
import { IPC_METHODS } from "@coffic/buddy-types";
import { logger } from "../utils/logger";

const ipc = window.ipc;

export const marketIpc = {
	// 获取用户插件列表
	async getUserPlugins(): Promise<SendablePlugin[]> {
		return await ipc.invoke(IPC_METHODS.GET_USER_PLUGINS);
	},

	// 获取开发插件列表
	async getDevPlugins(): Promise<SendablePlugin[]> {
		return await ipc.invoke(IPC_METHODS.GET_DEV_PLUGINS);
	},

	// 获取用户插件目录
	async getUserPluginDirectory(): Promise<string> {
		return await ipc.invoke(IPC_METHODS.GET_PLUGIN_DIRECTORIES);
	},

	// 下载插件
	async downloadPlugin(pluginId: string): Promise<void> {
		await ipc.invoke(IPC_METHODS.DOWNLOAD_PLUGIN, pluginId);
	},

	// 卸载插件
	async uninstallPlugin(pluginId: string): Promise<void> {
		await ipc.invoke(IPC_METHODS.UNINSTALL_PLUGIN, pluginId);
	},

	// 获取远程插件列表
	async getRemotePlugins(): Promise<SendablePlugin[]> {
		return await ipc.invoke(IPC_METHODS.GET_REMOTE_PLUGINS);
	},

	// 创建插件视图
	async createPluginView(pluginId: string): Promise<void> {
		return await ipc.invoke(IPC_METHODS.CREATE_PLUGIN_VIEW, pluginId);
	},

	// 判断某个插件是否已经安装
	async isInstalled(pluginId: string): Promise<boolean> {
		logger.debug('判断插件是否已经安装', pluginId)

		return await ipc.invoke(IPC_METHODS.Plugin_Is_Installed, pluginId);
	},
};
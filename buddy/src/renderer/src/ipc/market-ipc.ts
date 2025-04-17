
import { SendablePlugin } from "@/types/sendable-plugin";
import { IPC_METHODS, IpcResponse } from "@coffic/buddy-types";

const ipc = window.ipc;

export const marketIpc = {
	// 获取用户插件列表
	async getUserPlugins(): Promise<IpcResponse<SendablePlugin[]>> {
		const response = await ipc.invoke(IPC_METHODS.GET_USER_PLUGINS);

		return response as IpcResponse<SendablePlugin[]>;
	},

	// 获取开发插件列表
	async getDevPlugins(): Promise<IpcResponse<SendablePlugin[]>> {
		const response = await ipc.invoke(IPC_METHODS.GET_DEV_PLUGINS);

		return response as IpcResponse<SendablePlugin[]>;
	},

	// 获取用户插件目录
	async getUserPluginDirectory(): Promise<IpcResponse<string>> {
		const response = await ipc.invoke(IPC_METHODS.GET_PLUGIN_DIRECTORIES);

		return response as IpcResponse<string>;
	},

	// 下载插件
	async downloadPlugin(pluginId: string): Promise<IpcResponse<boolean>> {
		const response = await ipc.invoke(IPC_METHODS.DOWNLOAD_PLUGIN, pluginId);

		return response as IpcResponse<boolean>;
	},

	// 卸载插件
	async uninstallPlugin(pluginId): Promise<IpcResponse<boolean>> {
		const response = await ipc.invoke(IPC_METHODS.UNINSTALL_PLUGIN, pluginId);
		return response as IpcResponse<boolean>;
	},

	// 获取远程插件列表
	async getRemotePlugins(): Promise<IpcResponse<SendablePlugin[]>> {
		const response = await ipc.invoke(IPC_METHODS.GET_REMOTE_PLUGINS);
		return response as IpcResponse<SendablePlugin[]>;
	},

	// 创建插件视图
	async createPluginView(pluginId: string): Promise<unknown> {
		return await ipc.invoke(IPC_METHODS.CREATE_PLUGIN_VIEW, pluginId);
	},

	// 判断某个插件是否已经安装
	async has(pluginId: string): Promise<boolean> {
		const response = await ipc.invoke(IPC_METHODS.Plugin_Is_Installed, pluginId);

		return response.data as boolean;
	},
};
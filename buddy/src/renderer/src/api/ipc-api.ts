const electronApi = window.electron;
const ipc = electronApi.ipc;

export const ipcApi = {
  async openFolder(folder: string): Promise<string> {
    return await ipc.openFolder(folder);
  },

  /**
   * 打开配置文件夹
   * 先获取配置文件夹路径，然后打开它
   */
  async openConfigFolder(): Promise<string> {
    const configPath = await window.electron.config.getConfigPath();
    return await ipc.openFolder(configPath);
  }
};
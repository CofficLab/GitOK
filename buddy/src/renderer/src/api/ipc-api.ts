
const electronApi = window.electron;
const ipc = electronApi.ipc;

export const ipcApi = {
  async openFolder(folder: string): Promise<string> {
    return await ipc.openFolder(folder);
  },
};
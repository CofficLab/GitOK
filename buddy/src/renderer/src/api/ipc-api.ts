
const electronApi = window.electron;
const ipc = electronApi.ipc;

export const ipcAPI = {
  async openFolder(folder: string): Promise<void> {
    return await ipc.openFolder(folder);
  },
};
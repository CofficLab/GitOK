import { logger } from "../utils/logger";

const electronApi = window.electron;
const ipc = electronApi.ipc;

export const ipcAPI = {
  async openFolder(folder: string): Promise<string> {
    logger.info("openFolder", folder);
    return await ipc.openFolder(folder);
  },
};
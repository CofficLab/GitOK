import { IpcResponse } from "@coffic/buddy-types";
import { IPC_METHODS } from "@/types/ipc-methods.js";

const ipc = window.ipc;

export const fileIpc = {
    async openFolder(folder: string): Promise<unknown> {
        return await ipc.invoke(IPC_METHODS.Open_Folder, folder);
    },

    /**
     * 打开配置文件夹
     * 先获取配置文件夹路径，然后打开它
     */
    async openConfigFolder(): Promise<void> {
        const response: IpcResponse<unknown> = await ipc.invoke(IPC_METHODS.CONFIG_GET_PATH);

        if (response.success) {
            this.openFolder(response.data! as string)
        } else {
            throw new Error(response.error)
        }
    }
};
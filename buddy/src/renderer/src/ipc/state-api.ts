import { IpcResponse } from "@coffic/buddy-types";
import { IPC_METHODS } from "@/types/ipc-methods.js";

const ipc = window.ipc;

export const stateApi = {
    async getCurrentApp(): Promise<unknown> {
        const response: IpcResponse<any> = await ipc.invoke(IPC_METHODS.Get_Current_App);

        if (response.success) {
            return response.data;
        } else {
            throw new Error(response.error);
        }
    },
};
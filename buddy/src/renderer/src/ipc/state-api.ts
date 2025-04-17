import { IPC_METHODS, IpcResponse } from "@coffic/buddy-types";

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
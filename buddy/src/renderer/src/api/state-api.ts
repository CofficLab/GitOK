import { IPC_METHODS } from '@/types/ipc-methods';
import { IpcResponse } from '@/types/ipc-response';

const ipc = window.electron.ipc;

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
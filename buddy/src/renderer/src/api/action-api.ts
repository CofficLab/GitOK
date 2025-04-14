import { IPC_METHODS } from "@/types/ipc-methods";
import { IpcResponse } from "@/types/ipc-response";
import { SuperPlugin } from "@/types/super_plugin";

const electronApi = window.electron;
const pluginApi = electronApi.plugins;
const { management } = pluginApi;

export const actionApi = {
};
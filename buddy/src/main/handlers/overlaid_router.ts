/**
 * 被覆盖应用相关IPC处理函数
 */
import { IPC_METHODS } from '@/types/ipc-methods.js';
import { appStateManager } from '../managers/StateManager.js';
import { IpcRoute } from '../provider/RouterService.js';

/**
 * 被覆盖应用相关的IPC路由配置
 */
export const routes: IpcRoute[] = [
  {
    channel: IPC_METHODS.Get_Current_App,
    handler: () => appStateManager.getOverlaidApp()
  },
];

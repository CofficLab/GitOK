/**
 * 被覆盖应用相关IPC处理函数
 */
import { IPC_METHODS } from '@coffic/buddy-types';
import { appStateManager } from '../managers/StateManager';
import { IpcRoute } from '../provider/RouterService';

/**
 * 被覆盖应用相关的IPC路由配置
 */
export const routes: IpcRoute[] = [
  {
    channel: IPC_METHODS.Get_Current_App,
    handler: () => appStateManager.getOverlaidApp()
  },
];

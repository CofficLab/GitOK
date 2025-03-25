/**
 * IPC路由服务
 * 负责自动注册和管理所有的IPC路由
 */
import { ipcMain } from 'electron';
import { ipcLogger as logger } from '../managers/LogManager';

export type IpcHandler = (...args: any[]) => Promise<any> | any;

export interface IpcRoute {
  channel: string;
  handler: IpcHandler;
}

export class RouterService {
  private static instance: RouterService;
  private routes: IpcRoute[] = [];

  private constructor() {}

  public static getInstance(): RouterService {
    if (!RouterService.instance) {
      RouterService.instance = new RouterService();
    }
    return RouterService.instance;
  }

  /**
   * 注册路由
   * @param routes IPC路由配置
   */
  public registerRoutes(routes: IpcRoute[]): void {
    this.routes.push(...routes);
  }

  /**
   * 初始化所有路由
   */
  public initialize(): void {
    logger.info('开始初始化IPC路由...');

    for (const { channel, handler } of this.routes) {
      logger.debug(`注册IPC路由: ${channel}`);
      ipcMain.handle(channel, handler);
    }

    logger.info('IPC路由初始化完成');
  }
}

export const routerService = RouterService.getInstance();

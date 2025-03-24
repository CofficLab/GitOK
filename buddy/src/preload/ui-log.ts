/**
 * UI 日志模块
 * 处理前端日志的预加载脚本
 */
import { ipcRenderer } from 'electron';
import { UILogApi } from '@/types/ui-log-api';

export const uiLogApi: UILogApi = {
  info: (message: string): Promise<void> =>
    ipcRenderer.invoke('ui:log:info', message),

  error: (message: string): Promise<void> =>
    ipcRenderer.invoke('ui:log:error', message),

  warn: (message: string): Promise<void> =>
    ipcRenderer.invoke('ui:log:warn', message),

  debug: (message: string): Promise<void> =>
    ipcRenderer.invoke('ui:log:debug', message),
};

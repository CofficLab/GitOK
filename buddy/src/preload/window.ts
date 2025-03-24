/**
 * 窗口配置模块
 * 处理窗口相关的配置和状态管理
 */
import { ipcRenderer } from 'electron';
import { WindowConfig } from '@/types/window-config';
import { WindowApi } from '@/types/window-api';

export const windowApi: WindowApi = {
  getWindowConfig: (): Promise<WindowConfig> =>
    ipcRenderer.invoke('get-window-config'),
  setWindowConfig: (config: Partial<WindowConfig>): Promise<void> =>
    ipcRenderer.invoke('set-window-config', config),
  onWindowConfigChanged: (
    callback: (event: Electron.IpcRendererEvent, config: WindowConfig) => void
  ): (() => void) => {
    ipcRenderer.on('window-config-changed', callback);
    return () => {
      ipcRenderer.removeListener('window-config-changed', callback);
    };
  },
};

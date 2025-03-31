/**
 * 被覆盖应用模块
 * 处理应用被其他窗口覆盖的状态变化
 */
import { ipcRenderer } from 'electron';
import { OverlaidApi } from '@/types/api-overlaid';

export const overlaidApi: OverlaidApi = {
  onOverlaidAppChanged: (
    callback: (app: { name: string; bundleId: string } | null) => void
  ): (() => void) => {
    const listener = (_: Electron.IpcRendererEvent, app: any) => callback(app);
    ipcRenderer.on('overlaid-app-changed', listener);
    return () => {
      ipcRenderer.removeListener('overlaid-app-changed', listener);
    };
  },
};

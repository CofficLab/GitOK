/**
 * Command 键相关模块
 * 处理 Command 键双击和窗口激活/隐藏等功能
 */
import { ipcRenderer } from 'electron';
import { CommandApi } from '@/types/command-api';

export const commandApi: CommandApi = {
  toggleCommandDoublePress: (
    enabled: boolean
  ): Promise<{ success: boolean; reason?: string; already?: boolean }> =>
    ipcRenderer.invoke('toggle-command-double-press', enabled),

  onCommandDoublePressed: (
    callback: (event: Electron.IpcRendererEvent) => void
  ): (() => void) => {
    ipcRenderer.on('command-double-pressed', callback);
    return () => {
      ipcRenderer.removeListener('command-double-pressed', callback);
    };
  },

  onWindowHiddenByCommand: (
    callback: (event: Electron.IpcRendererEvent) => void
  ): (() => void) => {
    ipcRenderer.on('window-hidden-by-command', callback);
    return () => {
      ipcRenderer.removeListener('window-hidden-by-command', callback);
    };
  },

  onWindowActivatedByCommand: (
    callback: (event: Electron.IpcRendererEvent) => void
  ): (() => void) => {
    ipcRenderer.on('window-activated-by-command', callback);
    return () => {
      ipcRenderer.removeListener('window-activated-by-command', callback);
    };
  },
};

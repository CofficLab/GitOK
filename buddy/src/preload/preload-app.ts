/**
 * 预加载脚本入口文件
 * 整合所有模块并暴露给渲染进程
 */
import { contextBridge } from 'electron';
import { ipcApi } from './ipc';
import { commandApi } from './command';
import { pluginApi } from './plugin';
import { updateApi } from './update';
import { contextMenuApi } from './contextMenu';
import { aiApi } from './ai';
import { ElectronApi } from '@coffic/buddy-types';

// 整合所有 API
const api: ElectronApi = {
  ipc: ipcApi,
  ai: aiApi,
  command: commandApi,
  plugins: pluginApi,
  update: updateApi,
  contextMenu: contextMenuApi,
};

// 使用 contextBridge 暴露 API 到渲染进程
if (process.contextIsolated) {
  try {
    contextBridge.exposeInMainWorld('electron', api);
  } catch (error) {
    console.error(error);
  }
} else {
  // @ts-ignore (define in dts)
  window.electron = api;
}

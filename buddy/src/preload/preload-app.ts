/**
 * 预加载脚本入口文件
 * 整合所有模块并暴露给渲染进程
 */
import { contextBridge } from 'electron';
import { ipcApi } from './ipc.js';
import { pluginApi } from './plugin.js';
import { updateApi } from './update.js';
import { aiApi } from './ai.js';
import { ElectronApi } from '@coffic/buddy-types';

// 整合所有 API
const api: ElectronApi = {
  ipc: ipcApi,
  ai: aiApi,
  plugins: pluginApi,
  update: updateApi
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

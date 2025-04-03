/**
 * 预加载脚本入口文件
 * 整合所有模块并暴露给渲染进程
 */
import { contextBridge } from 'electron';
import { ipcApi } from './ipc';
import { commandApi } from './command';
import { pluginApi } from './plugin';
import { overlaidApi } from './overlaid';
import { uiLogApi } from './ui-log';
import { updateApi } from './update';
import { contextMenuApi } from './contextMenu';

// 整合所有 API
const api = {
  ipc: ipcApi,
  command: commandApi,
  plugins: pluginApi,
  overlaid: overlaidApi,
  ui: uiLogApi,
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

/**
 * 插件视图预加载脚本
 * 为插件视图提供与主应用通信的安全API
 */
import { contextBridge, ipcRenderer } from 'electron';

// 提供给插件视图的API
const pluginAPI = {
  // 向主应用发送消息
  sendToHost: (channel: string, data: any): void => {
    ipcRenderer.send('plugin-to-host', { channel, data });
  },

  // 从主应用接收消息
  receiveFromHost: (
    channel: string,
    callback: (data: any) => void
  ): (() => void) => {
    const listener = (
      _: Electron.IpcRendererEvent,
      message: { channel: string; data: any }
    ) => {
      if (message.channel === channel) {
        callback(message.data);
      }
    };

    ipcRenderer.on('host-to-plugin', listener);

    // 返回清理函数
    return () => {
      ipcRenderer.removeListener('host-to-plugin', listener);
    };
  },

  // 获取插件元数据
  getPluginInfo: (): Promise<any> => {
    return ipcRenderer.invoke('get-plugin-info');
  },

  // 退出视图
  close: (): void => {
    ipcRenderer.send('plugin-close-view');
  },
};

// 暴露API到插件视图全局环境
if (process.contextIsolated) {
  try {
    contextBridge.exposeInMainWorld('gitok', pluginAPI);
  } catch (error) {
    console.error('暴露插件API到全局环境失败:', error);
  }
} else {
  // @ts-ignore
  window.gitok = pluginAPI;
}

// 通知主进程插件视图已加载
window.addEventListener('DOMContentLoaded', () => {
  ipcRenderer.send('plugin-view-ready');
});

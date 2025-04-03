/**
 * 上下文菜单模块
 * 提供右键菜单功能
 */
import { ipcRenderer } from 'electron';

export const contextMenuApi = {
    /**
     * 显示上下文菜单
     * @param type 菜单类型，如 'text' 或 'chat-message'
     * @param hasSelection 是否选中了文本
     */
    showContextMenu: (type: string, hasSelection: boolean): void => {
        ipcRenderer.send('show-context-menu', { type, hasSelection });
    },

    /**
     * 监听复制代码块事件
     * @param callback 复制代码块时的回调函数
     * @returns 取消监听的函数
     */
    onCopyCode: (callback: () => void): (() => void) => {
        const handler = () => callback();
        ipcRenderer.on('context-menu-copy-code', handler);

        return () => {
            ipcRenderer.removeListener('context-menu-copy-code', handler);
        };
    }
}; 
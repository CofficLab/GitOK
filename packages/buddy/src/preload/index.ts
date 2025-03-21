import { contextBridge, ipcRenderer } from "electron"
import { electronAPI } from "@electron-toolkit/preload"

interface WindowConfig {
    showTrafficLights: boolean
}

// Custom APIs for renderer
const api = {
    // 已有的 API
    ...electronAPI,
    // 添加配置相关的 API
    getWindowConfig: (): Promise<WindowConfig> => ipcRenderer.invoke("get-window-config"),
    setWindowConfig: (config: Partial<WindowConfig>): Promise<void> =>
        ipcRenderer.invoke("set-window-config", config),
    onWindowConfigChanged: (
        callback: (event: Electron.IpcRendererEvent, config: WindowConfig) => void
    ): (() => void) => {
        ipcRenderer.on("window-config-changed", callback)
        return () => {
            ipcRenderer.removeListener("window-config-changed", callback)
        }
    },
    // 添加Command键双击功能的API
    toggleCommandDoublePress: (
        enabled: boolean
    ): Promise<{ success: boolean; reason?: string; already?: boolean }> =>
        ipcRenderer.invoke("toggle-command-double-press", enabled),
    onCommandDoublePressed: (
        callback: (event: Electron.IpcRendererEvent) => void
    ): (() => void) => {
        ipcRenderer.on("command-double-pressed", callback)
        return () => {
            ipcRenderer.removeListener("command-double-pressed", callback)
        }
    },
    // 添加窗口通过Command键隐藏和激活的事件处理函数
    onWindowHiddenByCommand: (
        callback: (event: Electron.IpcRendererEvent) => void
    ): (() => void) => {
        ipcRenderer.on("window-hidden-by-command", callback)
        return () => {
            ipcRenderer.removeListener("window-hidden-by-command", callback)
        }
    },
    onWindowActivatedByCommand: (
        callback: (event: Electron.IpcRendererEvent) => void
    ): (() => void) => {
        ipcRenderer.on("window-activated-by-command", callback)
        return () => {
            ipcRenderer.removeListener("window-activated-by-command", callback)
        }
    }
}

// Use `contextBridge` APIs to expose Electron APIs to
// renderer only if context isolation is enabled, otherwise
// just add to the DOM global.
if (process.contextIsolated) {
    try {
        contextBridge.exposeInMainWorld("electron", api)
    } catch (error) {
        console.error(error)
    }
} else {
    // @ts-ignore (define in dts)
    window.electron = api
}

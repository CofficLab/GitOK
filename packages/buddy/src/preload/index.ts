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

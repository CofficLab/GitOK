/// <reference types="vite/client" />

import { PluginsAPI } from "./types/plugins"

interface WindowConfig {
  showTrafficLights: boolean
}

interface MCPAPI {
  start: () => Promise<{ success: boolean; message: string }>
  stop: () => Promise<{ success: boolean; message: string }>
  sendCommand: (command: string) => Promise<{ success: boolean; response: string }>
  saveConfig: (config: {
    scriptPath: string
    startupCommands: string[]
  }) => Promise<{ success: boolean; message: string }>
  getConfig: () => Promise<{ scriptPath: string; startupCommands: string[] }>
  openFileDialog: () => Promise<string | null>
}

interface ElectronAPI {
  getWindowConfig: () => Promise<WindowConfig>
  setWindowConfig: (config: Partial<WindowConfig>) => Promise<void>
  onWindowConfigChanged: (
    callback: (event: Electron.IpcRendererEvent, config: WindowConfig) => void
  ) => () => void
  ipcRenderer: {
    send: (channel: "ping") => void
  }
  process: {
    versions: {
      electron: string
      chrome: string
      node: string
    }
  }
}

interface Window {
  electron: ElectronAPI
  api: {
    plugins: PluginsAPI
    mcp: MCPAPI
    send: (channel: string, ...args: unknown[]) => void
    receive: (channel: string, callback: (...args: unknown[]) => void) => void
    removeListener: (channel: string, callback: (...args: unknown[]) => void) => void
  }
}

declare global {
  interface Window {
    api: Window["api"]
  }
}

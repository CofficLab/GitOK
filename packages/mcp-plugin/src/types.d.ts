declare module "*.vue" {
  import type { DefineComponent } from "vue"
  const component: DefineComponent<{}, {}, any>
  export default component
}

declare interface Window {
  api: {
    mcp: {
      start: () => Promise<{ success: boolean; message: string }>
      stop: () => Promise<{ success: boolean; message: string }>
      sendCommand: (command: string) => Promise<{ success: boolean; response: string }>
      saveConfig: (config: {
        scriptPath: string
        startupCommands: string[]
      }) => Promise<{ success: boolean; message: string }>
      getConfig: () => Promise<{ scriptPath: string; startupCommands: string[] }>
      openFileDialog?: () => Promise<string | null>
    }
    plugins: any
  }
}

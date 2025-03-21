import { app, ipcMain, dialog } from "electron"
import path from "path"
import fs from "fs"
import { BuddyPlugin } from "../../buddy/src/main/plugins/types"

/**
 * MCP服务配置
 */
interface MCPConfig {
  scriptPath: string
  startupCommands: string[]
}

/**
 * 模拟MCP核心库
 */
class MCPCore {
  private scriptPath: string
  private isRunning = false

  constructor(scriptPath: string) {
    this.scriptPath = scriptPath
  }

  async start(): Promise<void> {
    if (this.isRunning) {
      return
    }

    this.isRunning = true
    console.log(`启动MCP服务，脚本路径: ${this.scriptPath}`)

    // 实际实现中，这里会启动子进程
    return Promise.resolve()
  }

  async stop(): Promise<void> {
    if (!this.isRunning) {
      return
    }

    this.isRunning = false
    console.log("停止MCP服务")

    // 实际实现中，这里会终止子进程
    return Promise.resolve()
  }

  async sendCommand(command: string): Promise<string> {
    if (!this.isRunning) {
      throw new Error("MCP服务未运行")
    }

    console.log(`发送命令: ${command}`)
    // 实际实现中，这里会向子进程发送命令
    return Promise.resolve(`执行命令 "${command}" 的结果`)
  }
}

/**
 * MCP插件实现
 */
class MCPPlugin implements BuddyPlugin {
  id = "mcp-plugin"
  name = "MCP调试工具"
  version = "1.0.0"
  description = "MCP脚本调试工具插件"

  private mcpService: MCPCore | null = null
  private configPath: string
  private config: MCPConfig = {
    scriptPath: "",
    startupCommands: []
  }

  constructor() {
    // 配置文件路径
    this.configPath = path.join(app.getPath("userData"), "mcp-config.json")
  }

  /**
   * 初始化插件
   */
  async initialize(): Promise<void> {
    console.log("MCP插件初始化中...")

    // 加载配置
    this.loadConfig()

    // 注册IPC处理程序
    this.registerIpcHandlers()

    return Promise.resolve()
  }

  /**
   * 激活插件
   */
  async activate(): Promise<void> {
    console.log("MCP插件已激活")
    return Promise.resolve()
  }

  /**
   * 停用插件
   */
  async deactivate(): Promise<void> {
    console.log("MCP插件停用中...")

    // 停止MCP服务
    if (this.mcpService) {
      await this.mcpService.stop()
      this.mcpService = null
    }

    return Promise.resolve()
  }

  /**
   * 注册IPC处理程序
   */
  registerIpcHandlers(): void {
    // 要注册的所有处理程序通道
    const channels = [
      "mcp:start",
      "mcp:stop",
      "mcp:sendCommand",
      "mcp:saveConfig",
      "mcp:getConfig",
      "mcp:openFileDialog"
    ]

    // 先移除所有可能已存在的处理程序
    for (const channel of channels) {
      try {
        ipcMain.removeHandler(channel)
        console.log(`已移除现有IPC处理程序: ${channel}`)
      } catch {
        // 移除不存在的处理程序会抛出错误，可以忽略
      }
    }

    // 启动MCP服务
    ipcMain.handle("mcp:start", async (): Promise<{ success: boolean; message: string }> => {
      try {
        if (this.mcpService) {
          return { success: false, message: "MCP服务已经在运行" }
        }

        // 创建MCP服务实例
        this.mcpService = new MCPCore(this.config.scriptPath)

        // 启动服务
        await this.mcpService.start()

        // 执行启动命令
        for (const command of this.config.startupCommands) {
          if (command.trim()) {
            await this.mcpService.sendCommand(command)
          }
        }

        return { success: true, message: "MCP服务启动成功" }
      } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error)
        return { success: false, message: `启动MCP服务失败: ${errorMessage}` }
      }
    })

    // 停止MCP服务
    ipcMain.handle("mcp:stop", async (): Promise<{ success: boolean; message: string }> => {
      try {
        if (!this.mcpService) {
          return { success: false, message: "MCP服务未运行" }
        }

        await this.mcpService.stop()
        this.mcpService = null

        return { success: true, message: "MCP服务已停止" }
      } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error)
        return { success: false, message: `停止MCP服务失败: ${errorMessage}` }
      }
    })

    // 发送命令到MCP服务
    ipcMain.handle(
      "mcp:sendCommand",
      async (_, command: string): Promise<{ success: boolean; response: string }> => {
        try {
          if (!this.mcpService) {
            return { success: false, response: "MCP服务未运行" }
          }

          const response = await this.mcpService.sendCommand(command)
          return { success: true, response }
        } catch (error) {
          const errorMessage = error instanceof Error ? error.message : String(error)
          return { success: false, response: `发送命令失败: ${errorMessage}` }
        }
      }
    )

    // 保存MCP配置
    ipcMain.handle(
      "mcp:saveConfig",
      (_, config: MCPConfig): { success: boolean; message: string } => {
        try {
          this.config = config
          fs.writeFileSync(this.configPath, JSON.stringify(config, null, 2))
          return { success: true, message: "配置已保存" }
        } catch (error) {
          const errorMessage = error instanceof Error ? error.message : String(error)
          return { success: false, message: `保存配置失败: ${errorMessage}` }
        }
      }
    )

    // 加载MCP配置
    ipcMain.handle("mcp:getConfig", (): MCPConfig => {
      return this.config
    })

    // 打开文件对话框
    ipcMain.handle("mcp:openFileDialog", async (): Promise<string | null> => {
      try {
        const result = await dialog.showOpenDialog({
          properties: ["openFile"],
          filters: [
            { name: "JavaScript", extensions: ["js"] },
            { name: "TypeScript", extensions: ["ts"] },
            { name: "所有文件", extensions: ["*"] }
          ]
        })

        if (!result.canceled && result.filePaths.length > 0) {
          return result.filePaths[0]
        }
        return null
      } catch (error) {
        console.error("打开文件对话框失败:", error)
        return null
      }
    })
  }

  /**
   * 加载配置
   */
  private loadConfig(): void {
    try {
      if (fs.existsSync(this.configPath)) {
        const configData = fs.readFileSync(this.configPath, "utf-8")
        this.config = JSON.parse(configData)
      } else {
        // 创建默认配置
        this.saveDefaultConfig()
      }
    } catch (error) {
      console.error("加载MCP配置失败:", error)
      this.saveDefaultConfig()
    }
  }

  /**
   * 保存默认配置
   */
  private saveDefaultConfig(): void {
    try {
      const defaultConfig: MCPConfig = {
        scriptPath: "",
        startupCommands: []
      }

      fs.writeFileSync(this.configPath, JSON.stringify(defaultConfig, null, 2))
      this.config = defaultConfig
    } catch (error) {
      console.error("保存默认MCP配置失败:", error)
    }
  }
}

// 导出插件实例
const mcpPlugin = new MCPPlugin()
export default mcpPlugin

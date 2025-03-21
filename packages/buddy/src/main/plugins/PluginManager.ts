/**
 * 插件管理器
 * 负责发现、加载、激活和管理插件
 */

import * as fs from "fs"
import * as path from "path"
import { app } from "electron"
import { BuddyPlugin, BuddyPluginConfig, BuddyPluginViewInfo } from "./types"

export class PluginManager {
  private plugins: Map<string, BuddyPlugin> = new Map()
  private pluginPaths: string[] = []
  private pluginConfigs: Map<string, { packagePath: string; config: BuddyPluginConfig }> = new Map()
  private activePlugins: Set<string> = new Set()

  constructor() {
    // 添加默认插件路径
    this.addPluginPath(path.join(app.getAppPath(), "..", "..", "packages"))

    // 添加用户插件目录
    const userPluginsDir = path.join(app.getPath("userData"), "plugins")
    if (!fs.existsSync(userPluginsDir)) {
      try {
        fs.mkdirSync(userPluginsDir, { recursive: true })
      } catch (error) {
        console.error("创建用户插件目录失败:", error)
      }
    }
    this.addPluginPath(userPluginsDir)
  }

  /**
   * 添加插件搜索路径
   */
  addPluginPath(pluginPath: string): void {
    if (fs.existsSync(pluginPath)) {
      this.pluginPaths.push(pluginPath)
      console.log(`添加插件搜索路径: ${pluginPath}`)
    } else {
      console.warn(`插件路径不存在: ${pluginPath}`)
    }
  }

  /**
   * 发现所有可用插件
   */
  async discoverPlugins(): Promise<void> {
    console.log("开始发现插件...")
    this.pluginConfigs.clear()

    for (const pluginPath of this.pluginPaths) {
      console.log(`搜索插件路径: ${pluginPath}`)
      try {
        const dirs = fs.readdirSync(pluginPath)

        for (const dir of dirs) {
          const packageJsonPath = path.join(pluginPath, dir, "package.json")

          if (fs.existsSync(packageJsonPath)) {
            try {
              const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, "utf8"))

              // 检查是否为Buddy插件
              if (packageJson.buddy) {
                const buddyConfig = packageJson.buddy as BuddyPluginConfig
                const entryPath = path.join(pluginPath, dir, buddyConfig.entry)

                if (fs.existsSync(entryPath)) {
                  // 存储插件配置信息
                  this.pluginConfigs.set(buddyConfig.id, {
                    packagePath: path.join(pluginPath, dir),
                    config: buddyConfig
                  })

                  console.log(`发现插件: ${buddyConfig.name} (${buddyConfig.id})`)
                } else {
                  console.warn(`插件入口文件不存在: ${entryPath}`)
                }
              }
            } catch (error) {
              console.error(`解析插件${dir}的package.json失败:`, error)
            }
          }
        }
      } catch (error) {
        console.error(`读取插件目录失败: ${pluginPath}`, error)
      }
    }

    console.log(`共发现${this.pluginConfigs.size}个插件`)
  }

  /**
   * 加载特定的插件
   */
  async loadPlugin(id: string): Promise<BuddyPlugin | null> {
    const pluginConfigInfo = this.pluginConfigs.get(id)

    if (!pluginConfigInfo) {
      console.warn(`插件未找到: ${id}`)
      return null
    }

    // 如果插件已加载，直接返回
    if (this.plugins.has(id)) {
      return this.plugins.get(id) || null
    }

    const { packagePath, config } = pluginConfigInfo
    const entryPath = path.join(packagePath, config.entry)

    try {
      console.log(`加载插件: ${config.name} (${config.id})`)

      // 动态导入插件
      const pluginModule = await import(entryPath)
      const Plugin = pluginModule.default

      if (!Plugin) {
        throw new Error(`插件${id}没有默认导出`)
      }

      let plugin: BuddyPlugin

      if (typeof Plugin === "function") {
        // 创建插件实例 - 如果是类
        plugin = new Plugin(config)
      } else if (typeof Plugin === "object" && Plugin !== null) {
        // 直接使用导出的对象 - 如果是实例
        plugin = Plugin
      } else {
        throw new Error(`插件${id}导出格式不正确，应为类或实例`)
      }

      // 初始化插件
      await plugin.initialize()

      // 存储插件实例
      this.plugins.set(id, plugin)

      console.log(`插件${config.name}加载成功`)
      return plugin
    } catch (error) {
      console.error(`加载插件${id}失败:`, error)
      return null
    }
  }

  /**
   * 加载所有已发现的插件
   */
  async loadAllPlugins(): Promise<void> {
    console.log("开始加载所有插件...")

    for (const id of this.pluginConfigs.keys()) {
      await this.loadPlugin(id)
    }

    console.log(`已加载${this.plugins.size}个插件`)
  }

  /**
   * 激活特定的插件
   */
  async activatePlugin(id: string): Promise<boolean> {
    console.log(`尝试激活插件: ${id}`)

    // 如果插件未加载，先加载插件
    if (!this.plugins.has(id)) {
      const plugin = await this.loadPlugin(id)
      if (!plugin) {
        return false
      }
    }

    const plugin = this.plugins.get(id)
    if (!plugin) {
      return false
    }

    try {
      // 激活插件
      await plugin.activate()
      this.activePlugins.add(id)

      // 如果插件有注册IPC处理器方法，则调用它
      if (plugin.registerIpcHandlers) {
        plugin.registerIpcHandlers()
      }

      console.log(`插件${plugin.name}激活成功`)
      return true
    } catch (error) {
      console.error(`激活插件${id}失败:`, error)
      return false
    }
  }

  /**
   * 停用特定的插件
   */
  async deactivatePlugin(id: string): Promise<boolean> {
    console.log(`尝试停用插件: ${id}`)

    const plugin = this.plugins.get(id)
    if (!plugin) {
      return false
    }

    try {
      // 停用插件
      await plugin.deactivate()
      this.activePlugins.delete(id)

      console.log(`插件${plugin.name}停用成功`)
      return true
    } catch (error) {
      console.error(`停用插件${id}失败:`, error)
      return false
    }
  }

  /**
   * 激活所有已加载的插件
   */
  async activateAllPlugins(): Promise<void> {
    console.log("激活所有已加载的插件...")

    for (const id of this.plugins.keys()) {
      await this.activatePlugin(id)
    }

    console.log(`已激活${this.activePlugins.size}个插件`)
  }

  /**
   * 停用所有已激活的插件
   */
  async deactivateAllPlugins(): Promise<void> {
    console.log("停用所有已激活的插件...")

    for (const id of this.activePlugins) {
      await this.deactivatePlugin(id)
    }

    console.log("所有插件已停用")
  }

  /**
   * 获取插件实例
   */
  getPlugin(id: string): BuddyPlugin | undefined {
    return this.plugins.get(id)
  }

  /**
   * 获取所有插件
   */
  getAllPlugins(): BuddyPlugin[] {
    return Array.from(this.plugins.values())
  }

  /**
   * 获取所有插件的视图信息
   */
  getAllViews(): BuddyPluginViewInfo[] {
    const views: BuddyPluginViewInfo[] = []

    for (const [pluginId, plugin] of this.plugins.entries()) {
      // 如果插件未激活，跳过
      if (!this.activePlugins.has(pluginId)) {
        continue
      }

      // 如果插件没有视图，跳过
      if (!plugin.getViews) {
        continue
      }

      const pluginConfigInfo = this.pluginConfigs.get(pluginId)
      if (!pluginConfigInfo) {
        continue
      }

      // 获取插件的视图
      const pluginViews = plugin.getViews()

      for (const view of pluginViews) {
        views.push({
          ...view,
          id: `${pluginId}-${view.name}`.replace(/\s+/g, "-").toLowerCase(),
          pluginId,
          absolutePath: path.join(pluginConfigInfo.packagePath, view.component)
        })
      }
    }

    return views
  }

  /**
   * 获取所有插件配置
   */
  getAllPluginConfigs(): { id: string; config: BuddyPluginConfig }[] {
    return Array.from(this.pluginConfigs.entries()).map(([id, info]) => ({
      id,
      config: info.config
    }))
  }

  /**
   * 检查插件是否已激活
   */
  isPluginActive(id: string): boolean {
    return this.activePlugins.has(id)
  }
}

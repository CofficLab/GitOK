/**
 * 插件管理器
 * 负责协调插件的安装、加载和运行
 */
import { app } from 'electron';
import path from 'path';
import fs from 'fs';
import { EventEmitter } from 'events';

// 插件注册表类型定义
interface PluginRegistry {
  [pluginId: string]: {
    version: string;
    installedAt: string;
    enabled: boolean;
    source: string;
  };
}

export class PluginManager extends EventEmitter {
  private pluginsDir: string;
  private registryPath: string;
  private registry: PluginRegistry = {};

  constructor() {
    super();
    // 设置插件目录在userData/plugins
    this.pluginsDir = path.join(app.getPath('userData'), 'plugins');
    this.registryPath = path.join(this.pluginsDir, 'registry.json');

    console.log(`📁 插件管理器初始化: 插件目录 ${this.pluginsDir}`);

    // 确保插件目录存在
    this.ensurePluginDir();

    // 加载插件注册表
    this.loadRegistry();
  }

  /**
   * 确保插件目录存在
   */
  private ensurePluginDir(): void {
    if (!fs.existsSync(this.pluginsDir)) {
      console.log(`📂 创建插件目录: ${this.pluginsDir}`);
      fs.mkdirSync(this.pluginsDir, { recursive: true });
    } else {
      console.log(`📂 插件目录已存在: ${this.pluginsDir}`);
    }
  }

  /**
   * 加载插件注册表
   */
  private loadRegistry(): void {
    try {
      if (fs.existsSync(this.registryPath)) {
        console.log(`📄 读取插件注册表: ${this.registryPath}`);
        const data = fs.readFileSync(this.registryPath, 'utf-8');
        this.registry = JSON.parse(data);
        console.log(
          `📋 已加载 ${Object.keys(this.registry).length} 个插件到注册表`
        );
      } else {
        console.log(`📝 插件注册表不存在，创建新的注册表文件`);
        // 创建空的注册表文件
        this.saveRegistry();
      }
    } catch (error) {
      console.error('❌ 加载插件注册表失败:', error);
      this.registry = {};
    }
  }

  /**
   * 保存插件注册表
   */
  private saveRegistry(): void {
    try {
      console.log(
        `💾 保存插件注册表: ${Object.keys(this.registry).length} 个插件`
      );
      fs.writeFileSync(
        this.registryPath,
        JSON.stringify(this.registry, null, 2),
        'utf-8'
      );
      console.log(`✅ 插件注册表保存成功`);
    } catch (error) {
      console.error('❌ 保存插件注册表失败:', error);
    }
  }

  /**
   * 获取已安装的插件列表
   */
  public getInstalledPlugins(): PluginRegistry {
    console.log(
      `📋 获取已安装插件列表: ${Object.keys(this.registry).length} 个插件`
    );
    return { ...this.registry };
  }

  /**
   * 安装插件
   * @param pluginPath 插件路径，可以是本地文件或URL
   */
  public async installPlugin(pluginPath: string): Promise<boolean> {
    console.log(`📥 插件管理器: 安装插件 ${pluginPath}`);
    try {
      // 这里暂时用简化版实现，仅处理本地文件
      if (!fs.existsSync(pluginPath)) {
        console.error(`❌ 插件文件不存在: ${pluginPath}`);
        throw new Error(`插件文件不存在: ${pluginPath}`);
      }
      console.log(`✅ 插件文件存在: ${pluginPath}`);

      // TODO: 实现实际的插件解压和安装逻辑
      // 暂时只是演示，实际上需要解压插件包并读取manifest.json

      // 模拟一个插件ID和版本
      const pluginId = path.basename(pluginPath, path.extname(pluginPath));
      const version = '1.0.0';
      console.log(`🔖 生成插件信息: ID=${pluginId}, 版本=${version}`);

      // 更新注册表
      this.registry[pluginId] = {
        version,
        installedAt: new Date().toISOString(),
        enabled: true,
        source: 'local',
      };
      console.log(`📝 更新插件注册表: ${pluginId}`);

      // 保存注册表
      this.saveRegistry();

      console.log(`🎉 插件安装完成: ${pluginId}`);
      this.emit('plugin-installed', pluginId);
      return true;
    } catch (error) {
      console.error('❌ 安装插件失败:', error);
      return false;
    }
  }

  /**
   * 卸载插件
   * @param pluginId 插件ID
   */
  public uninstallPlugin(pluginId: string): boolean {
    console.log(`🗑️ 插件管理器: 卸载插件 ${pluginId}`);
    try {
      if (!this.registry[pluginId]) {
        console.warn(`⚠️ 要卸载的插件不存在: ${pluginId}`);
        return false;
      }
      console.log(`🔍 找到要卸载的插件: ${pluginId}`);

      // TODO: 实际删除插件文件夹
      const pluginDir = path.join(this.pluginsDir, pluginId);
      if (fs.existsSync(pluginDir)) {
        console.log(`🗂️ 删除插件目录: ${pluginDir}`);
        // 这里应添加实际的删除逻辑
      }

      // 从注册表中移除
      console.log(`📝 从注册表移除插件: ${pluginId}`);
      delete this.registry[pluginId];
      this.saveRegistry();

      console.log(`✅ 插件卸载完成: ${pluginId}`);
      this.emit('plugin-uninstalled', pluginId);
      return true;
    } catch (error) {
      console.error('❌ 卸载插件失败:', error);
      return false;
    }
  }
}

// 导出单例
export const pluginManager = new PluginManager();

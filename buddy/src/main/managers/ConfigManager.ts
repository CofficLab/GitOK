import { app } from 'electron';
import { join } from 'path';
import fs from 'fs';
import yaml from 'js-yaml';
import type { WindowConfig } from '@/types/window-config';
import type { PluginManagerConfig } from '@/types/config';
import { logger } from './LogManager';

/**
 * 配置管理器
 * 负责管理应用的配置信息
 */
class ConfigManager {
  private static instance: ConfigManager;
  private configPath: string;
  private config: any;

  private constructor() {
    this.configPath = join(app.getAppPath(), 'config.yaml');
    this.loadConfig();
  }

  /**
   * 获取 ConfigManager 实例
   */
  public static getInstance(): ConfigManager {
    if (!ConfigManager.instance) {
      ConfigManager.instance = new ConfigManager();
    }
    return ConfigManager.instance;
  }

  /**
   * 加载配置文件
   */
  private loadConfig(): void {
    try {
      logger.info('加载配置文件', { path: this.configPath });
      const configContent = fs.readFileSync(this.configPath, 'utf8');
      this.config = yaml.load(configContent);
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      logger.error('加载配置文件失败', { error: errorMessage });
      this.config = {};
    }
  }

  /**
   * 获取完整配置
   */
  getConfig(): any {
    return this.config || {};
  }

  /**
   * 获取窗口配置
   */
  getWindowConfig(): WindowConfig {
    return this.config.window || {};
  }

  /**
   * 获取插件管理器配置
   */
  getPluginConfig(): PluginManagerConfig {
    return this.config.plugin || {};
  }
}

// 导出单例
export const configManager = ConfigManager.getInstance();

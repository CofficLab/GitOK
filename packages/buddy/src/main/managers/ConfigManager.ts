import { app } from 'electron';
import { join } from 'path';
import fs from 'fs';
import YAML from 'yaml';
import { Logger } from '../utils/Logger';

/**
 * 窗口配置接口
 */
export interface WindowConfig {
  showTrafficLights: boolean;
  showDebugToolbar: boolean;
  debugToolbarPosition?: 'right' | 'bottom' | 'left' | 'undocked';
  spotlightMode: boolean;
  spotlightHotkey?: string;
  spotlightSize?: { width: number; height: number };
  alwaysOnTop?: boolean;
  followDesktop?: boolean;
}

/**
 * 应用配置接口
 */
interface AppConfig {
  window: WindowConfig;
}

/**
 * 默认配置
 */
const defaultConfig: AppConfig = {
  window: {
    showTrafficLights: true,
    showDebugToolbar: false,
    debugToolbarPosition: 'right',
    spotlightMode: false,
    spotlightHotkey: 'CommandOrControl+Space',
    spotlightSize: { width: 700, height: 500 },
    alwaysOnTop: true,
    followDesktop: true,
  },
};

/**
 * 配置管理器
 * 单例模式，只负责读取配置
 */
class ConfigManager {
  private static instance: ConfigManager;
  private config: AppConfig;
  private logger: Logger;

  private constructor() {
    this.logger = new Logger('ConfigManager');
    this.config = this.loadConfig();
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
  private loadConfig(): AppConfig {
    const configPath = join(app.getAppPath(), 'config.yaml');
    this.logger.debug(`加载配置文件: ${configPath}`);

    try {
      if (fs.existsSync(configPath)) {
        const configContent = fs.readFileSync(configPath, 'utf8');
        const loadedConfig = YAML.parse(configContent) as Partial<AppConfig>;
        return {
          window: { ...defaultConfig.window, ...loadedConfig.window },
        };
      }
    } catch (err) {
      this.logger.error('加载配置文件失败', {
        error: err instanceof Error ? err.message : String(err),
      });
    }

    return { ...defaultConfig };
  }

  /**
   * 获取窗口配置
   */
  public getWindowConfig(): WindowConfig {
    return { ...this.config.window };
  }
}

// 导出单例
export const configManager = ConfigManager.getInstance();

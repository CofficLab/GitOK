import { app } from 'electron';
import { join } from 'path';
import fs from 'fs';
import YAML from 'yaml';
import { Logger } from '../utils/Logger';

export interface WindowConfig {
  showTrafficLights: boolean;
  showDebugToolbar: boolean;
  debugToolbarPosition?: 'right' | 'bottom' | 'left' | 'undocked';
  // Spotlight模式配置
  spotlightMode: boolean;
  spotlightHotkey?: string; // 全局快捷键
  spotlightSize?: { width: number; height: number }; // 窗口尺寸
  alwaysOnTop?: boolean; // 是否保持在最上层
  followDesktop?: boolean; // 是否跟随当前桌面/工作区
}

interface AppConfig {
  window: WindowConfig;
}

const defaultConfig: AppConfig = {
  window: {
    showTrafficLights: true,
    showDebugToolbar: false,
    debugToolbarPosition: 'right',
    // Spotlight默认配置
    spotlightMode: false,
    spotlightHotkey: 'CommandOrControl+Space',
    spotlightSize: { width: 700, height: 500 },
    alwaysOnTop: true,
    followDesktop: true,
  },
};

export class ConfigManager {
  private configPath: string;
  private config: AppConfig;
  private logger: Logger;

  constructor() {
    // 配置文件路径设置在应用根目录
    this.configPath = join(app.getAppPath(), 'config.yaml');
    this.logger = new Logger('ConfigManager');
    this.logger.info('ConfigManager 初始化');
    this.config = this.loadConfig();
  }

  /**
   * 加载配置文件
   */
  private loadConfig(): AppConfig {
    this.logger.debug(`加载配置文件: ${this.configPath}`);
    try {
      if (fs.existsSync(this.configPath)) {
        const configContent = fs.readFileSync(this.configPath, 'utf8');
        const loadedConfig = YAML.parse(configContent) as Partial<AppConfig>;
        this.logger.debug('配置文件加载成功');
        return this.mergeConfig(defaultConfig, loadedConfig);
      } else {
        this.logger.info('配置文件不存在，使用默认配置');
        return { ...defaultConfig };
      }
    } catch (err) {
      this.logger.error('加载配置文件失败', {
        error: err instanceof Error ? err.message : String(err),
      });
      return { ...defaultConfig };
    }
  }

  /**
   * 合并配置项
   */
  private mergeConfig(
    defaultConfig: AppConfig,
    loadedConfig: Partial<AppConfig>
  ): AppConfig {
    const result = { ...defaultConfig };

    // 合并窗口配置
    if (loadedConfig.window) {
      result.window = { ...defaultConfig.window, ...loadedConfig.window };
    }

    this.logger.debug('配置项合并完成');
    return result;
  }

  /**
   * 保存配置到文件
   */
  public saveConfig(): void {
    this.logger.debug('保存配置到文件');
    try {
      const configContent = YAML.stringify(this.config);
      fs.writeFileSync(this.configPath, configContent, 'utf8');
      this.logger.info('配置保存成功');
    } catch (err) {
      this.logger.error('保存配置失败', {
        error: err instanceof Error ? err.message : String(err),
      });
    }
  }

  /**
   * 获取窗口配置
   */
  public getWindowConfig(): WindowConfig {
    this.logger.debug('获取窗口配置');
    return { ...this.config.window };
  }

  /**
   * 设置窗口配置
   */
  public setWindowConfig(config: Partial<WindowConfig>): void {
    this.logger.info('设置窗口配置');
    this.config.window = { ...this.config.window, ...config };
    this.saveConfig();
  }

  /**
   * 重置窗口配置到默认值
   */
  public resetWindowConfig(): WindowConfig {
    this.logger.info('重置窗口配置到默认值');
    this.config.window = { ...defaultConfig.window };
    this.saveConfig();
    return this.getWindowConfig();
  }
}

export const configManager = new ConfigManager();

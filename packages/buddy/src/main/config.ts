import { app } from 'electron';
import { join } from 'path';
import fs from 'fs';
import YAML from 'yaml';

export interface WindowConfig {
  showTrafficLights: boolean;
  showDebugToolbar: boolean;
  debugToolbarPosition?: 'right' | 'bottom' | 'left' | 'undocked';
}

interface AppConfig {
  window: WindowConfig;
}

const defaultConfig: AppConfig = {
  window: {
    showTrafficLights: true,
    showDebugToolbar: false,
    debugToolbarPosition: 'right',
  },
};

export class ConfigManager {
  private configPath: string;
  private config: AppConfig;

  constructor() {
    // 配置文件路径设置在应用根目录
    this.configPath = join(app.getAppPath(), 'config.yaml');
    this.config = this.loadConfig();
  }

  private loadConfig(): AppConfig {
    try {
      if (fs.existsSync(this.configPath)) {
        const fileContent = fs.readFileSync(this.configPath, 'utf-8');
        const loadedConfig = YAML.parse(fileContent);
        // 合并默认配置和加载的配置
        return this.mergeConfig(defaultConfig, loadedConfig);
      }
    } catch (error) {
      console.error('Error loading config:', error);
    }
    return { ...defaultConfig };
  }

  private mergeConfig(
    defaultConfig: AppConfig,
    loadedConfig: Partial<AppConfig>
  ): AppConfig {
    return {
      window: {
        ...defaultConfig.window,
        ...loadedConfig.window,
      },
    };
  }

  public saveConfig(): void {
    try {
      const yamlStr = YAML.stringify(this.config);
      fs.writeFileSync(this.configPath, yamlStr, 'utf-8');
    } catch (error) {
      console.error('Error saving config:', error);
    }
  }

  public getWindowConfig(): WindowConfig {
    return this.config.window;
  }

  public setWindowConfig(config: Partial<WindowConfig>): void {
    this.config.window = { ...this.config.window, ...config };
    this.saveConfig();
  }
}

export const configManager = new ConfigManager();

/**
 * 按键管理器
 * 负责处理macOS平台按键的监听和响应
 */
import { KeyListener } from '@coffic/key-listener';
import { logger } from './LogManager';
import { windowManager } from './WindowManager';

class KeyManager {
  private static instance: KeyManager;
  // 记录每个keyCode上次按下的时间
  private lastPressTime: { [key: number]: number } = {};
  // 双击时间阈值（毫秒）
  private static readonly DOUBLE_PRESS_THRESHOLD = 300;

  /**
   * 获取 CommandKeyManager 实例
   */
  public static getInstance(): KeyManager {
    if (!KeyManager.instance) {
      KeyManager.instance = new KeyManager();
    }
    return KeyManager.instance;
  }

  /**
   * 设置Command键双击监听器
   */
  async setupCommandKeyListener(): Promise<{ success: boolean; error?: string }> {
    logger.info('开始设置Command键双击监听器');
    // 创建监听器实例
    const listener = new KeyListener();

    // 监听键盘事件
    listener.on('keypress', (event) => {
      if (event.keyCode == 54 || event.keyCode == 55) {
        const now = Date.now();
        const lastTime = this.lastPressTime[event.keyCode] || 0;

        // 检查是否是双击（两次按键间隔小于阈值）
        if (now - lastTime < KeyManager.DOUBLE_PRESS_THRESHOLD) {
          windowManager.toggleMainWindow();
        }

        // 更新最后按键时间
        this.lastPressTime[event.keyCode] = now;
      }
    });

    // 启动监听器（返回Promise）
    listener.start().then(success => {
      if (success) {
        logger.info('监听器已启动');
      } else {
        logger.error('监听器启动失败');
      }
    });

    // ... 应用其他逻辑 ...

    // 停止监听（不再需要时）
    // listener.stop();

    return {
      success: false
    };
  }
}

// 导出单例
export const commandKeyManager = KeyManager.getInstance();

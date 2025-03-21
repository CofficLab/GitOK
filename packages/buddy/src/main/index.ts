import { app, shell, BrowserWindow, ipcMain } from 'electron';
import { join } from 'path';
import { electronApp, optimizer, is } from '@electron-toolkit/utils';
import icon from '../../resources/icon.png?asset';
import { configManager, type WindowConfig } from './config';
import { initPluginSystem } from './plugins';

// 声明CommandKeyListener类型但不导入模块
interface CommandKeyListener {
  start(): Promise<boolean>;
  stop(): boolean;
  isListening(): boolean;
  on(event: 'command-double-press', listener: () => void): CommandKeyListener;
}

// 创建一个全局变量来存储命令键监听器实例
let commandKeyListener: CommandKeyListener | null = null;

// 标记应用是否正在退出
let isQuitting = false;

function createWindow(): void {
  const windowConfig = configManager.getWindowConfig();
  const showTrafficLights = windowConfig.showTrafficLights;
  const showDebugToolbar = windowConfig.showDebugToolbar;
  const debugToolbarPosition = windowConfig.debugToolbarPosition || 'right';

  // Create the browser window.
  const mainWindow = new BrowserWindow({
    width: 1200,
    height: 1000,
    show: false,
    autoHideMenuBar: true,
    ...(process.platform === 'linux' ? { icon } : {}),
    // macOS 特定配置
    ...(process.platform === 'darwin'
      ? {
          titleBarStyle: showTrafficLights ? 'default' : 'hiddenInset',
          trafficLightPosition: showTrafficLights
            ? undefined
            : { x: -20, y: -20 },
        }
      : {}),
    webPreferences: {
      preload: join(__dirname, '../preload/index.js'),
      sandbox: false,
    },
  });

  mainWindow.on('ready-to-show', () => {
    mainWindow.show();

    // 根据配置决定是否打开开发者工具及其位置
    if (showDebugToolbar) {
      mainWindow.webContents.openDevTools({
        mode: debugToolbarPosition,
      });
    }
  });

  mainWindow.webContents.setWindowOpenHandler((details) => {
    shell.openExternal(details.url);
    return { action: 'deny' };
  });

  // HMR for renderer base on electron-vite cli.
  // Load the remote URL for development or the local html file for production.
  if (is.dev && process.env['ELECTRON_RENDERER_URL']) {
    mainWindow.loadURL(process.env['ELECTRON_RENDERER_URL']);
  } else {
    mainWindow.loadFile(join(__dirname, '../renderer/index.html'));
  }

  // 仅在macOS上设置Command键双击监听器
  if (process.platform === 'darwin') {
    setupCommandKeyListener(mainWindow);
  }
}

/**
 * 设置Command键双击监听器
 * @param window 要激活的窗口
 */
function setupCommandKeyListener(window: BrowserWindow): void {
  // 如果监听器已经存在，先停止它
  if (commandKeyListener) {
    commandKeyListener.stop();
    commandKeyListener = null;
  }

  try {
    // 使用动态导入
    import('@cofficlab/command-key-listener')
      .then((module) => {
        const CommandKeyListenerClass = module.CommandKeyListener;

        // 创建新的监听器实例
        commandKeyListener = new CommandKeyListenerClass();

        if (!commandKeyListener) {
          console.error('创建Command键双击监听器实例失败');
          return;
        }

        // 监听双击Command键事件
        commandKeyListener.on('command-double-press', () => {
          if (window && !window.isDestroyed()) {
            // 切换窗口状态：如果窗口聚焦则隐藏，否则显示并聚焦
            if (window.isFocused()) {
              // 窗口当前在前台，隐藏它
              window.hide();
              // 发送事件到渲染进程通知窗口已隐藏
              window.webContents.send('window-hidden-by-command');
            } else {
              // 窗口当前不在前台，显示并聚焦它
              window.show();
              window.focus();
              // 发送事件到渲染进程通知窗口已激活
              window.webContents.send('window-activated-by-command');
            }
            // 无论如何都发送命令键双击事件
            window.webContents.send('command-double-pressed');
          }
        });

        // 异步启动监听器
        commandKeyListener
          .start()
          .then((result) => {
            if (result) {
              console.log('Command键双击监听器已启动');
            } else {
              console.error('Command键双击监听器启动失败');
            }
          })
          .catch((error) => {
            console.error('启动Command键双击监听器时出错:', error);
          });
      })
      .catch((error) => {
        console.error('加载Command键双击监听器模块失败:', error);
      });
  } catch (error) {
    console.error('初始化Command键双击监听器失败:', error);
  }
}

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
// Some APIs can only be used after this event occurs.
app.whenReady().then(async () => {
  // Set app user model id for windows
  electronApp.setAppUserModelId('com.electron');

  // Default open or close DevTools by F12 in development
  // and ignore CommandOrControl + R in production.
  // see https://github.com/alex8088/electron-toolkit/tree/master/packages/utils
  app.on('browser-window-created', (_, window) => {
    optimizer.watchWindowShortcuts(window);
  });

  // IPC test
  ipcMain.on('ping', () => console.log('pong'));

  createWindow();

  app.on('activate', function () {
    // On macOS it's common to re-create a window in the app when the
    // dock icon is clicked and there are no other windows open.
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });

  // 初始化插件系统
  initPluginSystem();
});

// 当所有窗口都关闭时，停止Command键监听器
app.on('window-all-closed', () => {
  // 停止监听器
  if (commandKeyListener) {
    commandKeyListener.stop();
    commandKeyListener = null;
  }

  if (process.platform !== 'darwin') {
    app.quit();
  }
});

// In this file you can include the rest of your app's specific main process
// code. You can also put them in separate files and require them here.

// 添加 IPC 处理程序来处理配置更改
ipcMain.handle('get-window-config', () => {
  return configManager.getWindowConfig();
});

ipcMain.handle('set-window-config', (_, config: Partial<WindowConfig>) => {
  configManager.setWindowConfig(config);
  // 通知所有窗口配置已更改
  BrowserWindow.getAllWindows().forEach((window) => {
    window.webContents.send(
      'window-config-changed',
      configManager.getWindowConfig()
    );
  });
});

// 添加 IPC 处理程序来控制Command键双击功能
ipcMain.handle('toggle-command-double-press', async (_, enabled: boolean) => {
  if (process.platform !== 'darwin') {
    return { success: false, reason: '此功能仅在macOS上可用' };
  }

  if (enabled) {
    if (commandKeyListener && commandKeyListener.isListening()) {
      return { success: true, already: true };
    }

    const mainWindow =
      BrowserWindow.getFocusedWindow() || BrowserWindow.getAllWindows()[0];
    if (mainWindow) {
      setupCommandKeyListener(mainWindow);
      // 由于设置过程是异步的，无法立即获取结果，返回启动中状态
      return { success: true, starting: true };
    }

    return { success: false, reason: '没有可用窗口' };
  } else {
    if (commandKeyListener) {
      const result = commandKeyListener.stop();
      commandKeyListener = null;
      return { success: result };
    }
    return { success: true, already: true };
  }
});

// 监听应用退出事件，停用所有插件
app.on('before-quit', async () => {
  // 如果已经在处理退出，则直接返回
  if (isQuitting) return;

  // 标记正在退出
  isQuitting = true;

  // 正常退出应用
  app.exit(0);
});

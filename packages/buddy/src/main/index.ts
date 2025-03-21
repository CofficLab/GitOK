import {
  app,
  shell,
  BrowserWindow,
  ipcMain,
  WebContentsView,
  BrowserView,
} from 'electron';
import { join } from 'path';
import { electronApp, optimizer, is } from '@electron-toolkit/utils';
import icon from '../../resources/icon.png?asset';
import { configManager, type WindowConfig } from './config';
// 添加类型导入但使用注释标记为需要时才加载
// @ts-ignore CommandKeyListener模块将在运行时动态导入
import type { CommandKeyListener } from '@cofficlab/command-key-listener';
// 导入插件系统
import { initializePluginSystem } from './plugins';

// 创建一个全局变量来存储命令键监听器实例
let commandKeyListener: CommandKeyListener | null = null;

// 标记应用是否正在退出
let isQuitting = false;

// 创建一个全局Map来存储插件视图
const pluginViews = new Map<string, BrowserView>();

function createWindow(): void {
  const windowConfig = configManager.getWindowConfig();
  const showTrafficLights = windowConfig.showTrafficLights;
  const showDebugToolbar = windowConfig.showDebugToolbar;
  const debugToolbarPosition = windowConfig.debugToolbarPosition || 'right';

  // Create the browser window.
  const mainWindow = new BrowserWindow({
    width: 1200,
    height: 1400,
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

/**
 * 创建插件WebContentsView
 * @param mainWindow 主窗口
 * @param viewId 视图ID
 * @param url 加载的URL或HTML文件路径
 */
function createPluginView(
  mainWindow: BrowserWindow,
  viewId: string,
  url: string
): BrowserView | null {
  try {
    console.log(`创建插件视图, ID: ${viewId}, URL: ${url}`);

    // 创建BrowserView而不是WebContentsView
    const view = new BrowserView({
      webPreferences: {
        nodeIntegration: false,
        contextIsolation: true,
        sandbox: true,
        preload: join(__dirname, '../preload/plugin-preload.js'),
        // 允许开发者工具
        devTools: true,
      },
    });

    // 存储视图引用
    pluginViews.set(viewId, view);

    // 加载URL或HTML内容
    if (url.startsWith('http://') || url.startsWith('https://')) {
      // 加载远程URL
      view.webContents.loadURL(url);
    } else if (
      url.startsWith('<html') ||
      url.startsWith('<!DOCTYPE') ||
      url.startsWith('data:')
    ) {
      // 直接加载HTML内容
      view.webContents.loadURL(
        `data:text/html;charset=utf-8,${encodeURIComponent(url)}`
      );
    } else {
      // 加载文件 - 这里假设url是相对于应用根目录的路径
      try {
        // 直接从插件获取HTML内容
        import('./plugins/index.js').then(async ({ pluginManager }) => {
          try {
            // 使用ActionView获取的viewPath对应的viewId来请求HTML内容
            // 假设viewId格式为 view_timestamp_actionId_random
            const parts = viewId.split('_');
            const actionId = parts.length >= 3 ? parts[2] : null;

            if (!actionId) {
              console.log('无法从视图ID中提取动作ID:', viewId);
              const errorHtml = `<html><body><h1>错误</h1><p>无法加载视图: 无效的视图ID</p></body></html>`;
              view.webContents.loadURL(
                `data:text/html;charset=utf-8,${encodeURIComponent(errorHtml)}`
              );
              return;
            }

            console.log(`尝试获取动作 ${actionId} 的视图内容`);

            // 获取所有动作
            const actions = await pluginManager.getAllActions();
            const action = actions.find((a) => a.id === actionId);

            if (!action) {
              console.log(`未找到动作: ${actionId}`);
              const errorHtml = `<html><body><h1>错误</h1><p>无法加载视图: 未找到动作</p></body></html>`;
              view.webContents.loadURL(
                `data:text/html;charset=utf-8,${encodeURIComponent(errorHtml)}`
              );
              return;
            }

            // 使用插件API获取视图内容
            const html = await pluginManager.getActionViewContent(actionId);
            console.log(`成功获取HTML内容，长度: ${html.length}`);
            view.webContents.loadURL(
              `data:text/html;charset=utf-8,${encodeURIComponent(html)}`
            );
          } catch (error: any) {
            console.error('获取视图内容失败:', error);
            const errorHtml = `<html><body><h1>错误</h1><p>加载视图失败: ${error?.message || '未知错误'}</p></body></html>`;
            view.webContents.loadURL(
              `data:text/html;charset=utf-8,${encodeURIComponent(errorHtml)}`
            );
          }
        });
      } catch (error: any) {
        console.error(`加载视图内容失败:`, error);
        const errorHtml = `<html><body><h1>错误</h1><p>加载视图失败: ${error?.message || '未知错误'}</p></body></html>`;
        view.webContents.loadURL(
          `data:text/html;charset=utf-8,${encodeURIComponent(errorHtml)}`
        );
      }
    }

    // 监听视图销毁事件，清理引用
    view.webContents.on('destroyed', () => {
      console.log(`插件视图已销毁: ${viewId}`);
      pluginViews.delete(viewId);
    });

    // 添加DOM就绪事件监听，在内容加载后自动打开开发者工具
    view.webContents.on('dom-ready', () => {
      console.log(`插件视图DOM已就绪: ${viewId}`);

      // 获取窗口配置
      const windowConfig = configManager.getWindowConfig();

      // 如果配置启用了开发者工具，则打开它
      if (windowConfig.showDebugToolbar) {
        view.webContents.openDevTools({
          mode: windowConfig.debugToolbarPosition || 'right',
        });
      }
    });

    return view;
  } catch (error) {
    console.error(`创建插件视图失败:`, error);
    return null;
  }
}

/**
 * 注册插件视图相关的IPC处理函数
 */
function registerPluginViewHandlers() {
  // 创建插件视图
  ipcMain.handle('create-plugin-view', async (event, { viewId, url }) => {
    const window = BrowserWindow.fromWebContents(event.sender);
    if (!window) {
      return { success: false, error: '无法找到主窗口' };
    }

    try {
      const view = createPluginView(window, viewId, url);
      if (!view) {
        return { success: false, error: '创建视图失败' };
      }
      return { success: true, viewId };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : String(error),
      };
    }
  });

  // 显示插件视图
  ipcMain.handle('show-plugin-view', async (event, { viewId, bounds }) => {
    const window = BrowserWindow.fromWebContents(event.sender);
    if (!window) {
      return { success: false, error: '无法找到主窗口' };
    }

    const view = pluginViews.get(viewId);
    if (!view) {
      return { success: false, error: `视图不存在: ${viewId}` };
    }

    try {
      // 显示视图
      window.setBrowserView(view);

      // 设置视图边界
      const viewBounds = bounds || {
        x: Math.floor(window.getBounds().width * 0.25), // 水平居中（左侧缩进25%）
        y: Math.floor(window.getBounds().height * 0.15), // 垂直方向稍微往下一点
        width: Math.floor(window.getBounds().width * 0.5), // 宽度为窗口的1/2
        height: Math.floor(window.getBounds().height * 0.6), // 高度为窗口的60%，留出状态栏空间
      };

      // 记录视图位置和大小
      console.log(`设置视图边界: ${JSON.stringify(viewBounds)}`);
      view.setBounds(viewBounds);

      return { success: true };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : String(error),
      };
    }
  });

  // 隐藏插件视图
  ipcMain.handle('hide-plugin-view', async (event, { viewId }) => {
    const window = BrowserWindow.fromWebContents(event.sender);
    if (!window) {
      return { success: false, error: '无法找到主窗口' };
    }

    try {
      // 移除当前的BrowserView
      window.setBrowserView(null);
      return { success: true };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : String(error),
      };
    }
  });

  // 关闭并销毁插件视图
  ipcMain.handle('destroy-plugin-view', async (event, { viewId }) => {
    const window = BrowserWindow.fromWebContents(event.sender);
    if (!window) {
      return { success: false, error: '无法找到主窗口' };
    }

    const view = pluginViews.get(viewId);
    if (!view) {
      return { success: false, error: `视图不存在: ${viewId}` };
    }

    try {
      // 首先隐藏视图
      window.setBrowserView(null);

      // 从窗口中移除视图并从Map中删除
      window.removeBrowserView(view);
      pluginViews.delete(viewId);

      return { success: true };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : String(error),
      };
    }
  });

  // 处理插件视图发送给主应用的消息
  ipcMain.on('plugin-to-host', (event, { channel, data }) => {
    // 找到发送消息的视图
    const pluginViewId = findPluginViewIdByWebContents(event.sender);
    if (!pluginViewId) {
      console.error('无法找到发送消息的插件视图');
      return;
    }

    // 找到主窗口
    const mainWindow = BrowserWindow.getAllWindows().find((win) =>
      win
        .getBrowserViews()
        .some((view) => view.webContents.id === event.sender.id)
    );

    if (!mainWindow) {
      console.error('无法找到主窗口');
      return;
    }

    // 转发消息到主应用
    mainWindow.webContents.send('plugin-message', {
      viewId: pluginViewId,
      channel,
      data,
    });
  });

  // 处理从主应用发送到插件视图的消息
  ipcMain.on('host-to-plugin', (event, { viewId, channel, data }) => {
    // 找到对应的视图
    const view = pluginViews.get(viewId);
    if (!view) {
      console.error(`找不到插件视图: ${viewId}`);
      return;
    }

    // 转发消息到插件视图
    view.webContents.send('host-to-plugin', {
      channel,
      data,
    });
  });

  // 处理插件视图准备就绪的消息
  ipcMain.on('plugin-view-ready', (event) => {
    const viewId = findPluginViewIdByWebContents(event.sender);
    if (!viewId) {
      console.error('无法找到发送ready消息的插件视图');
      return;
    }

    console.log(`插件视图准备就绪: ${viewId}`);

    // 可以在这里执行一些初始化操作，比如发送插件信息
  });

  // 处理插件视图请求关闭的消息
  ipcMain.on('plugin-close-view', (event) => {
    const viewId = findPluginViewIdByWebContents(event.sender);
    if (!viewId) {
      console.error('无法找到请求关闭的插件视图');
      return;
    }

    console.log(`插件视图请求关闭: ${viewId}`);

    // 找到主窗口
    const mainWindow = BrowserWindow.getAllWindows().find((win) =>
      win
        .getBrowserViews()
        .some((view) => view.webContents.id === event.sender.id)
    );

    if (!mainWindow) {
      console.error('无法找到主窗口');
      return;
    }

    // 通知主应用插件视图请求关闭
    mainWindow.webContents.send('plugin-close-requested', {
      viewId,
    });
  });

  // 获取插件信息
  ipcMain.handle('get-plugin-info', (event) => {
    const viewId = findPluginViewIdByWebContents(event.sender);
    if (!viewId) {
      return { success: false, error: '无法找到插件视图' };
    }

    return {
      success: true,
      viewId,
      // 可以在这里添加更多插件相关信息
    };
  });

  // 切换插件视图的开发者工具
  ipcMain.handle('toggle-plugin-devtools', async (event, { viewId }) => {
    const view = pluginViews.get(viewId);
    if (!view) {
      return { success: false, error: `视图不存在: ${viewId}` };
    }

    try {
      if (view.webContents.isDevToolsOpened()) {
        view.webContents.closeDevTools();
        console.log(`已关闭插件视图的开发者工具: ${viewId}`);
      } else {
        // 获取窗口配置
        const windowConfig = configManager.getWindowConfig();
        view.webContents.openDevTools({
          mode: windowConfig.debugToolbarPosition || 'right',
        });
        console.log(`已打开插件视图的开发者工具: ${viewId}`);
      }
      return { success: true };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : String(error),
      };
    }
  });
}

/**
 * 根据WebContents查找对应的插件视图ID
 */
function findPluginViewIdByWebContents(
  webContents: Electron.WebContents
): string | null {
  for (const [viewId, view] of pluginViews.entries()) {
    if (view.webContents.id === webContents.id) {
      return viewId;
    }
  }
  return null;
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

  // 初始化插件系统
  initializePluginSystem();

  // 注册插件视图处理函数
  registerPluginViewHandlers();

  createWindow();

  app.on('activate', function () {
    // On macOS it's common to re-create a window in the app when the
    // dock icon is clicked and there are no other windows open.
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
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

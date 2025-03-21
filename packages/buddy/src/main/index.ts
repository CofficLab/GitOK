import { app, shell, BrowserWindow, ipcMain } from "electron"
import { join } from "path"
import { electronApp, optimizer, is } from "@electron-toolkit/utils"
import icon from "../../resources/icon.png?asset"
import { configManager, type WindowConfig } from "./config"
// 使用类型导入
import { CommandKeyListener } from "../types/command-key-listener"
import * as path from "path"

// 创建一个全局变量来存储命令键监听器实例
let commandKeyListener: CommandKeyListener | null = null

function createWindow(): void {
    const showTrafficLights = configManager.getWindowConfig().showTrafficLights

    // Create the browser window.
    const mainWindow = new BrowserWindow({
        width: 900,
        height: 670,
        show: false,
        autoHideMenuBar: true,
        ...(process.platform === "linux" ? { icon } : {}),
        // macOS 特定配置
        ...(process.platform === "darwin"
            ? {
                  titleBarStyle: showTrafficLights ? "default" : "hiddenInset",
                  trafficLightPosition: showTrafficLights ? undefined : { x: -20, y: -20 }
              }
            : {}),
        webPreferences: {
            preload: join(__dirname, "../preload/index.js"),
            sandbox: false
        }
    })

    mainWindow.on("ready-to-show", () => {
        mainWindow.show()
    })

    mainWindow.webContents.setWindowOpenHandler((details) => {
        shell.openExternal(details.url)
        return { action: "deny" }
    })

    // HMR for renderer base on electron-vite cli.
    // Load the remote URL for development or the local html file for production.
    if (is.dev && process.env["ELECTRON_RENDERER_URL"]) {
        mainWindow.loadURL(process.env["ELECTRON_RENDERER_URL"])
    } else {
        mainWindow.loadFile(join(__dirname, "../renderer/index.html"))
    }

    // 仅在macOS上设置Command键双击监听器
    if (process.platform === "darwin") {
        setupCommandKeyListener(mainWindow)
    }
}

/**
 * 设置Command键双击监听器
 * @param window 要激活的窗口
 */
function setupCommandKeyListener(window: BrowserWindow): void {
    // 尝试加载真实的CommandKeyListener实现
    try {
        // 从本地模块中导入真实的CommandKeyListener，使用.cjs扩展名
        const nativeModulePath = path.resolve(
            __dirname,
            "../../native/command-key-listener/index.cjs"
        )

        // 使用动态导入
        import(nativeModulePath)
            .then(async (module) => {
                const RealCommandKeyListener = module.default

                // 如果监听器已经存在，先停止它
                if (commandKeyListener) {
                    commandKeyListener.stop()
                    commandKeyListener = null
                }

                // 创建新的监听器实例
                commandKeyListener = new RealCommandKeyListener()

                if (!commandKeyListener) {
                    console.error("创建Command键双击监听器实例失败")
                    return
                }

                // 监听双击Command键事件
                commandKeyListener.on("command-double-press", () => {
                    if (window && !window.isDestroyed()) {
                        // 切换窗口状态：如果窗口聚焦则隐藏，否则显示并聚焦
                        if (window.isFocused()) {
                            // 窗口当前在前台，隐藏它
                            window.hide()
                            // 发送事件到渲染进程通知窗口已隐藏
                            window.webContents.send("window-hidden-by-command")
                        } else {
                            // 窗口当前不在前台，显示并聚焦它
                            window.show()
                            window.focus()
                            // 发送事件到渲染进程通知窗口已激活
                            window.webContents.send("window-activated-by-command")
                        }
                        // 无论如何都发送命令键双击事件
                        window.webContents.send("command-double-pressed")
                    }
                })

                // 异步启动监听器
                try {
                    const result = await commandKeyListener.start()
                    if (result) {
                        console.log("Command键双击监听器已启动 (真实实现)")
                    } else {
                        console.error("Command键双击监听器启动失败")
                    }
                } catch (error) {
                    console.error("启动Command键双击监听器时出错:", error)
                }
            })
            .catch((error) => {
                console.error("加载真实的Command键双击监听器失败:", error)
            })
    } catch (error) {
        console.error("加载真实的Command键双击监听器失败:", error)
    }
}

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
// Some APIs can only be used after this event occurs.
app.whenReady().then(() => {
    // Set app user model id for windows
    electronApp.setAppUserModelId("com.electron")

    // Default open or close DevTools by F12 in development
    // and ignore CommandOrControl + R in production.
    // see https://github.com/alex8088/electron-toolkit/tree/master/packages/utils
    app.on("browser-window-created", (_, window) => {
        optimizer.watchWindowShortcuts(window)
    })

    // IPC test
    ipcMain.on("ping", () => console.log("pong"))

    createWindow()

    app.on("activate", function () {
        // On macOS it's common to re-create a window in the app when the
        // dock icon is clicked and there are no other windows open.
        if (BrowserWindow.getAllWindows().length === 0) createWindow()
    })
})

// 当所有窗口都关闭时，停止Command键监听器
app.on("window-all-closed", () => {
    // 停止监听器
    if (commandKeyListener) {
        commandKeyListener.stop()
        commandKeyListener = null
    }

    if (process.platform !== "darwin") {
        app.quit()
    }
})

// In this file you can include the rest of your app's specific main process
// code. You can also put them in separate files and require them here.

// 添加 IPC 处理程序来处理配置更改
ipcMain.handle("get-window-config", () => {
    return configManager.getWindowConfig()
})

ipcMain.handle("set-window-config", (_, config: Partial<WindowConfig>) => {
    configManager.setWindowConfig(config)
    // 通知所有窗口配置已更改
    BrowserWindow.getAllWindows().forEach((window) => {
        window.webContents.send("window-config-changed", configManager.getWindowConfig())
    })
})

// 添加 IPC 处理程序来控制Command键双击功能
ipcMain.handle("toggle-command-double-press", (_, enabled: boolean) => {
    if (process.platform !== "darwin") {
        return { success: false, reason: "此功能仅在macOS上可用" }
    }

    if (enabled) {
        if (commandKeyListener && commandKeyListener.isListening()) {
            return { success: true, already: true }
        }

        const mainWindow = BrowserWindow.getFocusedWindow() || BrowserWindow.getAllWindows()[0]
        if (mainWindow) {
            setupCommandKeyListener(mainWindow)
            return { success: commandKeyListener?.isListening() || false }
        }

        return { success: false, reason: "没有可用窗口" }
    } else {
        if (commandKeyListener) {
            const result = commandKeyListener.stop()
            commandKeyListener = null
            return { success: result }
        }
        return { success: true, already: true }
    }
})

import { app, shell, BrowserWindow, ipcMain } from "electron"
import { join } from "path"
import { electronApp, optimizer, is } from "@electron-toolkit/utils"
import icon from "../../resources/icon.png?asset"
import { configManager, type WindowConfig } from "./config"

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

// Quit when all windows are closed, except on macOS. There, it's common
// for applications and their menu bar to stay active until the user quits
// explicitly with Cmd + Q.
app.on("window-all-closed", () => {
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

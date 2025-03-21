#!/usr/bin/env node

// 使用CommonJS语法
const { spawn } = require("child_process")
const path = require("path")
const fs = require("fs")

// 检查是否在macOS系统上
const isMac = process.platform === "darwin"
if (!isMac) {
    console.warn("警告: 该模块仅支持macOS系统。在其他系统上构建将提供一个虚拟实现。")
}

// 获取当前文件夹路径
const currentDir = __dirname

console.log("正在构建Command键双击监听器原生模块...")
console.log("当前目录:", currentDir)

// 确保build文件夹存在
const buildDir = path.join(currentDir, "build")
if (!fs.existsSync(buildDir)) {
    fs.mkdirSync(buildDir, { recursive: true })
}

// 调用node-gyp进行构建
const nodeGyp = spawn("node-gyp", ["rebuild"], {
    cwd: currentDir,
    stdio: "inherit",
    shell: true
})

nodeGyp.on("close", (code) => {
    if (code === 0) {
        console.log("原生模块构建成功!")
    } else {
        console.error(`构建失败，退出码: ${code}`)

        // 如果构建失败，创建一个空的模块
        if (!isMac) {
            console.log("在非macOS系统上创建虚拟模块...")
            createMockModule()
        }
    }
})

// 创建一个虚拟模块，供非macOS系统使用
function createMockModule() {
    const mockDir = path.join(buildDir, "Release")
    if (!fs.existsSync(mockDir)) {
        fs.mkdirSync(mockDir, { recursive: true })
    }

    const mockFilePath = path.join(mockDir, "command_key_listener.node")
    if (!fs.existsSync(mockFilePath)) {
        console.log(`创建虚拟模块文件: ${mockFilePath}`)
        fs.writeFileSync(mockFilePath, Buffer.from([0]))
    }
}

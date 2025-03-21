"use strict"

const { spawnSync } = require("child_process")
const fs = require("fs")
const path = require("path")
const os = require("os")

/**
 * 编译Command键双击监听器原生模块
 * 仅在macOS上实际编译，其他平台创建一个mock模块
 */
function buildNativeModule() {
    console.log("开始构建Command键双击监听器原生模块...")

    // 检查是否在macOS上运行
    const platform = os.platform()
    const isMacOS = platform === "darwin"

    // 目标目录
    const buildDir = path.join(__dirname, "..", "build", "Release")

    /**
     * 确保目录存在
     * @param {string} dir 目录路径
     */
    function ensureDirExists(dir) {
        if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir, { recursive: true })
        }
    }

    // 检查是否为macOS系统
    if (!isMacOS) {
        console.log("非macOS系统，创建模拟模块...")
        ensureDirExists(buildDir)
        const mockFilePath = path.join(buildDir, "command_key_listener.node")
        fs.writeFileSync(
            mockFilePath,
            `module.exports = {
                start: function() { console.warn('Command键双击监听器仅在macOS上可用'); return false; },
                stop: function() { return true; }
            };`
        )
        console.log("已创建模拟模块文件:", mockFilePath)
        return
    }

    // 在macOS系统上使用node-gyp编译原生模块
    console.log("在macOS上构建原生模块...")
    ensureDirExists(buildDir)

    // 使用node-gyp构建
    console.log("执行node-gyp rebuild...")
    const result = spawnSync("node-gyp", ["rebuild"], {
        cwd: __dirname,
        stdio: "inherit",
        shell: true
    })

    if (result.status !== 0) {
        console.error("构建失败，错误代码:", result.status)
        process.exit(1)
    }

    // 检查编译后的文件是否存在
    const sourcePath = path.join(__dirname, "build", "Release", "command_key_listener.node")
    const targetPath = path.join(buildDir, "command_key_listener.node")

    if (!fs.existsSync(sourcePath)) {
        console.error("错误: 编译后的.node文件不存在:", sourcePath)
        process.exit(1)
    }

    // 确保目标目录存在
    ensureDirExists(path.dirname(targetPath))

    // 复制编译后的文件到目标位置
    fs.copyFileSync(sourcePath, targetPath)
    console.log(`已复制编译后的模块到: ${targetPath}`)

    console.log("原生模块构建完成!")
}

// 执行构建
buildNativeModule()

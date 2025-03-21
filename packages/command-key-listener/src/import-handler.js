/**
 * 原生模块导入处理工具
 *
 * 此文件用于解决Node.js中ESM模式加载原生模块的问题
 */

// @ts-check
const path = require("path")
const os = require("os")
const fs = require("fs")

/**
 * 同步加载原生模块
 * @param {string} modulePath - 原生模块的路径
 * @returns {Object|null} 加载的模块或null
 */
function loadNativeModuleSync(modulePath) {
    try {
        // 在CommonJS环境中可直接使用require
        return require(modulePath)
    } catch (error) {
        console.error(`加载原生模块失败: ${modulePath}`, error)
        return null
    }
}

/**
 * 查找原生模块路径
 * @param {string} moduleName - 模块名称
 * @returns {string|null} 找到的模块路径或null
 */
function findNativeModulePath(moduleName) {
    // 检查是否在macOS上运行
    if (os.platform() !== "darwin") {
        console.warn("Command键双击监听器仅在macOS上可用")
        return null
    }

    // 可能的路径
    const possiblePaths = [
        // 相对于当前文件的路径
        path.join(__dirname, "..", "build", "Release", `${moduleName}.node`),
        // 全局安装的路径
        path.join(process.cwd(), "build", "Release", `${moduleName}.node`)
    ]

    // 查找存在的路径
    for (const modulePath of possiblePaths) {
        if (fs.existsSync(modulePath)) {
            return modulePath
        }
    }

    console.error(`找不到原生模块: ${moduleName}`)
    return null
}

/**
 * 加载Command键双击监听器原生模块
 * @returns {Object|null} 原生模块或null
 */
function loadCommandKeyListener() {
    const modulePath = findNativeModulePath("command_key_listener")
    if (!modulePath) {
        return null
    }

    return loadNativeModuleSync(modulePath)
}

module.exports = {
    loadCommandKeyListener
}

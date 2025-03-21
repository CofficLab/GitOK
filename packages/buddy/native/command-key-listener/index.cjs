"use strict"

const path = require("path")
const fs = require("fs")
const { EventEmitter } = require("events")

// 定义路径
const nativeModulePath = path.join(__dirname, "build", "Release", "command_key_listener.node")

// 初始化变量
let nativeModule = null

// 尝试加载原生模块
try {
    // 检查文件是否存在
    if (fs.existsSync(nativeModulePath)) {
        nativeModule = require(nativeModulePath)
        console.log("成功加载原生Command键双击监听器模块")
        console.log("原生模块结构:", Object.keys(nativeModule))
        console.log("原生模块类型:", typeof nativeModule)

        // 检查模块是否包含必要的函数
        if (typeof nativeModule.start === "function" && typeof nativeModule.stop === "function") {
            console.log("原生模块包含start和stop函数")
        } else {
            console.error("原生模块缺少必要的函数")
        }
    } else {
        console.error("找不到原生模块文件:", nativeModulePath)
    }
} catch (error) {
    console.error("加载原生Command键双击监听器模块失败:", error)
}

/**
 * Command键双击监听器
 */
class KeyDoubleClickListener extends EventEmitter {
    constructor() {
        super()
        this._isListening = false
        this._nativeModule = null

        // 检查原生模块是否可用
        if (
            nativeModule &&
            typeof nativeModule.start === "function" &&
            typeof nativeModule.stop === "function"
        ) {
            this._nativeModule = nativeModule
            console.log("原生Command键双击监听器可用")
        } else {
            console.error("原生Command键双击监听器不可用")
        }
    }

    /**
     * 开始监听双击Command键事件
     * @returns {Promise<boolean>} 是否成功启动监听的Promise
     */
    async start() {
        if (this._isListening) return true

        // 检查原生监听器是否可用
        if (!this._nativeModule) {
            console.error("原生Command键双击监听器不可用")
            return false
        }

        try {
            // 设置回调函数在双击Command键时触发
            const success = this._nativeModule.start(() => {
                // 触发事件
                this.emit("command-double-press")
                console.log("Command键双击事件触发")
            })

            if (!success) {
                console.error("启动原生Command键双击监听器失败")
                return false
            }

            this._isListening = true
            console.log("Command键双击监听器已成功启动")
            return true
        } catch (error) {
            console.error("启动Command键双击监听器时出错:", error.message)
            console.error("完整错误信息:", error)
            return false
        }
    }

    /**
     * 停止监听双击Command键事件
     * @returns {boolean} 是否成功停止监听
     */
    stop() {
        if (!this._isListening) return true

        if (this._nativeModule) {
            try {
                const success = this._nativeModule.stop()
                this._isListening = false
                console.log("Command键双击监听器已停止")
                return success
            } catch (error) {
                console.error("停止Command键双击监听器时出错:", error.message)
                this._isListening = false
                return false
            }
        }

        this._isListening = false
        return true
    }

    /**
     * 当前是否正在监听
     * @returns {boolean} 监听状态
     */
    isListening() {
        return this._isListening
    }
}

// 导出类 - CommonJS格式
module.exports = KeyDoubleClickListener
module.exports.default = KeyDoubleClickListener

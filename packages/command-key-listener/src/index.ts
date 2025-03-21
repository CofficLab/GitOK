import { EventEmitter } from "events"
import * as os from "os"
// 直接加载原生模块
import * as path from "path"

/**
 * Command键双击监听器接口
 */
export interface CommandKeyListenerInterface extends EventEmitter {
    /**
     * 启动监听器
     * @returns 返回监听器是否成功启动的Promise
     */
    start(): Promise<boolean>

    /**
     * 停止监听器
     * @returns 返回监听器是否成功停止
     */
    stop(): boolean

    /**
     * 获取监听器当前状态
     * @returns 当前是否正在监听
     */
    isListening(): boolean
}

/**
 * 原生模块接口
 */
interface NativeModuleInterface {
    start(callback: () => void): boolean
    stop(): boolean
}

// 辅助函数：加载原生模块
function loadNativeModule(): NativeModuleInterface | null {
    try {
        // 如果不是macOS系统，返回null
        if (os.platform() !== "darwin") {
            console.warn("警告: Command键双击监听器仅在macOS上可用")
            return null
        }

        // 寻找可能的模块路径
        const possiblePaths = [
            // 生产环境路径
            path.join(__dirname, "..", "build", "Release", "command_key_listener.node"),
            // 开发环境路径
            path.join(process.cwd(), "build", "Release", "command_key_listener.node")
        ]

        // 尝试加载模块
        for (const modulePath of possiblePaths) {
            try {
                if (require("fs").existsSync(modulePath)) {
                    return require(modulePath)
                }
            } catch (err) {
                // 忽略错误，继续尝试下一个路径
            }
        }

        console.error("找不到Command键双击监听器原生模块")
        return null
    } catch (error) {
        console.error("加载Command键双击监听器原生模块失败:", error)
        return null
    }
}

/**
 * Command键双击监听器
 *
 * 监听macOS系统上的Command键双击事件，当检测到双击时触发'command-double-press'事件。
 *
 * @example
 * ```
 * import { CommandKeyListener } from '@cofficlab/command-key-listener';
 *
 * const listener = new CommandKeyListener();
 *
 * listener.on('command-double-press', () => {
 *   console.log('Command键被双击了!');
 * });
 *
 * listener.start().then(success => {
 *   if (success) {
 *     console.log('监听器已启动');
 *   } else {
 *     console.error('监听器启动失败');
 *   }
 * });
 *
 * // 停止监听
 * // listener.stop();
 * ```
 */
export class CommandKeyListener extends EventEmitter implements CommandKeyListenerInterface {
    private _isListening: boolean
    private _nativeModule: NativeModuleInterface | null

    /**
     * 创建Command键双击监听器实例
     */
    constructor() {
        super()
        this._isListening = false

        // 检查平台，并尝试加载原生模块
        if (os.platform() !== "darwin") {
            console.warn("警告: Command键双击监听器仅在macOS上可用")
            this._nativeModule = null
        } else {
            // 使用导入处理器加载原生模块
            this._nativeModule = loadNativeModule()

            if (!this._nativeModule) {
                console.error("无法加载Command键双击监听器原生模块")
            }
        }
    }

    /**
     * 启动监听器
     * @returns 返回监听器是否成功启动的Promise
     */
    async start(): Promise<boolean> {
        if (this._isListening) return true

        // 检查原生模块是否可用
        if (!this._nativeModule) {
            console.error("原生Command键双击监听器不可用")
            return false
        }

        try {
            // 设置回调函数
            const success = this._nativeModule.start(() => {
                this.emit("command-double-press")
            })

            if (!success) {
                console.error("启动原生Command键双击监听器失败")
                return false
            }

            this._isListening = true
            return true
        } catch (error) {
            console.error("启动Command键双击监听器时出错:", error)
            return false
        }
    }

    /**
     * 停止监听器
     * @returns 返回监听器是否成功停止
     */
    stop(): boolean {
        if (!this._isListening) return true

        if (this._nativeModule) {
            try {
                const success = this._nativeModule.stop()
                this._isListening = false
                return success
            } catch (error) {
                console.error("停止Command键双击监听器时出错:", error)
                this._isListening = false
                return false
            }
        }

        this._isListening = false
        return true
    }

    /**
     * 获取监听器当前状态
     * @returns 当前是否正在监听
     */
    isListening(): boolean {
        return this._isListening
    }
}

export default CommandKeyListener

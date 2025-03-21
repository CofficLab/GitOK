import { EventEmitter } from "events"
import * as path from "path"
import * as fs from "fs"

// 定义原生模块的接口
interface INativeCommandKeyListener {
    start(callback: () => void): boolean
    stop(): boolean
}

interface NativeModule {
    CommandKeyListener: new () => INativeCommandKeyListener
}

// 直接加载原生模块（CommonJS方式，适用于Electron主进程）
let nativeModuleSync: NativeModule | null = null
try {
    const modulePath = path.join(__dirname, "build", "Release", "command_key_listener.node")
    if (fs.existsSync(modulePath)) {
        // eslint-disable-next-line @typescript-eslint/no-var-requires
        nativeModuleSync = require(modulePath) as NativeModule
        console.log("成功加载原生Command键双击监听器模块")
    } else {
        console.error("找不到原生模块文件:", modulePath)
    }
} catch (error) {
    console.error("加载原生Command键双击监听器模块失败:", error)
}

/**
 * Command键双击监听器
 */
class KeyDoubleClickListener extends EventEmitter {
    private _isListening: boolean = false
    private _nativeListener: INativeCommandKeyListener | null = null

    constructor() {
        super()
        this._isListening = false
        this._nativeListener = null

        // 尝试直接使用同步方式加载的模块
        if (nativeModuleSync) {
            try {
                this._nativeListener = new nativeModuleSync.CommandKeyListener()
            } catch (error) {
                console.error("创建原生监听器实例失败:", error)
                this._nativeListener = null
            }
        }
    }

    /**
     * 开始监听双击Command键事件
     * @returns 是否成功启动监听
     */
    public async start(): Promise<boolean> {
        if (this._isListening) return true

        // 检查原生监听器是否可用
        if (!this._nativeListener) {
            console.error("原生Command键双击监听器不可用")
            return false
        }

        try {
            // 设置回调函数在双击Command键时触发
            const success = this._nativeListener.start(() => {
                // 触发事件
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
     * 停止监听双击Command键事件
     * @returns 是否成功停止监听
     */
    public stop(): boolean {
        if (!this._isListening) return true

        if (this._nativeListener) {
            try {
                const success = this._nativeListener.stop()
                this._isListening = false
                return success
            } catch (error) {
                console.error("停止Command键双击监听器时出错:", error)
                return false
            }
        }

        this._isListening = false
        return true
    }

    /**
     * 当前是否正在监听
     * @returns 监听状态
     */
    public isListening(): boolean {
        return this._isListening
    }
}

// 导出类
export default KeyDoubleClickListener

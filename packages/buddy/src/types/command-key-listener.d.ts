import { EventEmitter } from "events"

export interface CommandKeyListener extends EventEmitter {
    /**
     * 开始监听双击Command键事件
     * @returns 是否成功启动监听
     */
    start(): Promise<boolean>

    /**
     * 停止监听双击Command键事件
     * @returns 是否成功停止监听
     */
    stop(): boolean

    /**
     * 当前是否正在监听
     * @returns 监听状态
     */
    isListening(): boolean
}

declare module "../../native/command-key-listener.js" {
    export default class CommandKeyListener extends EventEmitter {
        constructor()
        start(): boolean
        stop(): boolean
        isListening(): boolean
    }
}

// 也声明不带扩展名的版本，以确保兼容性
declare module "../../native/command-key-listener" {
    export default class CommandKeyListener extends EventEmitter {
        constructor()
        start(): boolean
        stop(): boolean
        isListening(): boolean
    }
}

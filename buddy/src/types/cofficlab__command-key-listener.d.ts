/**
 * @cofficlab/command-key-listener 类型声明
 */

import { EventEmitter } from "events"

declare module "@cofficlab/command-key-listener" {
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
     * Command键双击监听器
     */
    export class CommandKeyListener extends EventEmitter implements CommandKeyListenerInterface {
        /**
         * 创建Command键双击监听器实例
         */
        constructor()

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

        /**
         * 监听Command键双击事件
         * @param event 事件名称 'command-double-press'
         * @param listener 事件回调函数
         */
        on(event: "command-double-press", listener: () => void): this

        /**
         * 监听Command键双击事件（一次性）
         * @param event 事件名称 'command-double-press'
         * @param listener 事件回调函数
         */
        once(event: "command-double-press", listener: () => void): this
    }

    export default CommandKeyListener
}

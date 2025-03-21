import { EventEmitter } from "events"

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
export declare class CommandKeyListener
    extends EventEmitter
    implements CommandKeyListenerInterface
{
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

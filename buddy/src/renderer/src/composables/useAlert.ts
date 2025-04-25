/**
 * useAlert - 全局警告提示组合式函数
 * 
 * 提供简单易用的全局警告提示功能，基于 DaisyUI 的 alert 组件实现。
 * 
 * 使用示例：
 * ```typescript
 * // 引入全局实例
 * import { globalAlert } from '@/composables/useAlert'
 * 
 * // 基本使用
 * globalAlert.alert('这是一条警告消息')
 * 
 * // 不同类型的警告
 * globalAlert.success('操作成功')
 * globalAlert.error('发生错误')
 * globalAlert.warning('请注意')
 * globalAlert.info('这是一条提示信息')
 * 
 * // 自定义配置
 * globalAlert.success('保存成功', { 
 *   closable: true, // 显示关闭按钮
 *   duration: 5000  // 显示5秒
 * })
 * 
 * // 手动关闭
 * globalAlert.close()
 * ```
 * 
 * 可用方法：
 * - alert(message | options): 显示普通警告
 * - success(message, options?): 显示成功消息
 * - error(message, options?): 显示错误消息
 * - warning(message, options?): 显示警告消息
 * - info(message, options?): 显示信息消息
 * - close(): 关闭当前显示的警告
 */

import { ref } from 'vue'

// Alert 状态接口
interface AlertState {
    show: boolean
    type: 'success' | 'error' | 'warning' | 'info'
    message: string
    closable: boolean
    duration?: number
}

// 默认配置
const defaultOptions = {
    type: 'info' as const,
    message: '',
    closable: false,
    duration: undefined,
}

// 创建一个全局状态
const state = ref<AlertState>({
    show: false,
    ...defaultOptions,
})

/**
 * Alert 警告提示 Composable
 * 提供全局警告提示功能
 */
export function useAlert() {
    /**
     * 显示 Alert 警告
     * @param options 配置选项或消息字符串
     */
    const alert = (options: Partial<Omit<AlertState, 'show'>> | string) => {
        // 如果传入的是字符串，则作为消息内容
        if (typeof options === 'string') {
            options = { message: options }
        }

        // 关闭之前的 Alert
        state.value.show = false

        // 短暂延迟后显示新的 Alert，确保动画效果流畅
        setTimeout(() => {
            state.value = {
                ...state.value,
                ...defaultOptions,
                ...options,
                show: true,
            }

            // 如果有duration设置，自动关闭
            if (options.duration) {
                setTimeout(() => {
                    state.value.show = false
                }, options.duration)
            }
        }, 100)
    }

    /**
     * 显示成功消息
     * @param message 消息内容
     * @param options 其他配置选项
     */
    const success = (message: string, options: Partial<Omit<AlertState, 'show' | 'type' | 'message'>> = {}) => {
        alert({
            type: 'success',
            message,
            ...options,
        })
    }

    /**
     * 显示错误消息
     * @param message 消息内容
     * @param options 其他配置选项
     */
    const error = (message: string, options: Partial<Omit<AlertState, 'show' | 'type' | 'message'>> = {}) => {
        alert({
            type: 'error',
            message,
            ...options,
        })
    }

    /**
     * 显示警告消息
     * @param message 消息内容
     * @param options 其他配置选项
     */
    const warning = (message: string, options: Partial<Omit<AlertState, 'show' | 'type' | 'message'>> = {}) => {
        alert({
            type: 'warning',
            message,
            ...options,
        })
    }

    /**
     * 显示信息消息
     * @param message 消息内容
     * @param options 其他配置选项
     */
    const info = (message: string, options: Partial<Omit<AlertState, 'show' | 'type' | 'message'>> = {}) => {
        alert({
            type: 'info',
            message,
            ...options,
        })
    }

    /**
     * 关闭当前 Alert
     */
    const close = () => {
        state.value.show = false
    }

    return {
        state,
        alert,
        success,
        error,
        warning,
        info,
        close,
    }
}

// 创建一个全局实例
export const globalAlert = useAlert()
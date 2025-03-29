/**
 * useToast - 全局消息提示组合式函数
 * 
 * 提供简单易用的全局消息提示功能，基于 DaisyUI 的 toast 组件实现。
 * 
 * 使用示例：
 * ```typescript
 * // 引入全局实例
 * import { globalToast } from '@/composables/useToast'
 * 
 * // 基本使用
 * globalToast.toast('这是一条普通消息')
 * 
 * // 不同类型的消息
 * globalToast.success('操作成功完成')
 * globalToast.error('发生错误')
 * globalToast.warning('请注意')
 * globalToast.info('这是一条提示信息')
 * 
 * // 自定义配置
 * globalToast.success('保存成功', { 
 *   position: 'bottom-center', // 在底部中间显示
 *   duration: 5000            // 显示5秒
 * })
 * 
 * // 手动关闭
 * globalToast.close()
 * ```
 * 
 * 可用方法：
 * - toast(message | options): 显示普通消息
 * - success(message, options?): 显示成功消息
 * - error(message, options?): 显示错误消息
 * - warning(message, options?): 显示警告消息
 * - info(message, options?): 显示信息消息
 * - close(): 关闭当前显示的消息
 */

import { ref } from 'vue'

// Toast 状态接口
interface ToastState {
  show: boolean
  type: 'default' | 'success' | 'error' | 'warning' | 'info'
  message: string
  duration: number
  position: 'top-start' | 'top-center' | 'top-end' | 'bottom-start' | 'bottom-center' | 'bottom-end'
}

// 默认配置
const defaultOptions = {
  type: 'default' as const,
  message: '',
  duration: 2000,
  position: 'top-center' as const,
}

// 创建一个全局状态
const state = ref<ToastState>({
  show: false,
  ...defaultOptions,
})

/**
 * Toast 消息提示 Composable
 * 提供全局消息提示功能
 */
export function useToast() {
  /**
   * 显示 Toast 消息
   * @param options 配置选项或消息字符串
   */
  const toast = (options: Partial<Omit<ToastState, 'show'>> | string) => {
    // 如果传入的是字符串，则作为消息内容
    if (typeof options === 'string') {
      options = { message: options }
    }

    // 关闭之前的 Toast
    state.value.show = false
    
    // 短暂延迟后显示新的 Toast，确保动画效果流畅
    setTimeout(() => {
      state.value = {
        ...state.value,
        ...defaultOptions,
        ...options,
        show: true,
      }
    }, 100)
  }

  /**
   * 显示成功消息
   * @param message 消息内容
   * @param options 其他配置选项
   */
  const success = (message: string, options: Partial<Omit<ToastState, 'show' | 'type' | 'message'>> = {}) => {
    toast({
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
  const error = (message: string, options: Partial<Omit<ToastState, 'show' | 'type' | 'message'>> = {}) => {
    toast({
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
  const warning = (message: string, options: Partial<Omit<ToastState, 'show' | 'type' | 'message'>> = {}) => {
    toast({
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
  const info = (message: string, options: Partial<Omit<ToastState, 'show' | 'type' | 'message'>> = {}) => {
    toast({
      type: 'info',
      message,
      ...options,
    })
  }

  /**
   * 关闭当前 Toast
   */
  const close = () => {
    state.value.show = false
  }

  return {
    state,
    toast,
    success,
    error,
    warning,
    info,
    close,
  }
}

// 创建一个全局实例
export const globalToast = useToast()

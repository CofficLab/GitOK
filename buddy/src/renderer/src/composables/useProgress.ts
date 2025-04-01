/**
 * useProgress - 全局进度条组合式函数
 * 
 * 提供简单易用的全局进度条功能，基于 DaisyUI 的 progress 组件实现。
 * 
 * 使用示例：
 * ```typescript
 * // 引入全局实例
 * import { globalProgress } from '@/composables/useProgress'
 * 
 * // 显示不确定进度
 * globalProgress.start()
 * 
 * // 显示确定进度
 * globalProgress.start(30) // 显示30%进度
 * globalProgress.update(50)  // 更新到50%
 * globalProgress.update(80)  // 更新到80%
 * 
 * // 完成并隐藏进度条
 * globalProgress.finish()
 * 
 * // 直接隐藏进度条
 * globalProgress.hide()
 * 
 * // 自定义颜色
 * globalProgress.start(0, { color: 'primary' })
 * ```
 */

import { ref } from 'vue'

// 进度条状态接口
interface ProgressState {
    show: boolean
    value?: number
    max: number
    color: 'neutral' | 'primary' | 'secondary' | 'accent' | 'info' | 'success' | 'warning' | 'error'
}

// 进度条配置选项
interface ProgressOptions {
    max?: number
    color?: ProgressState['color']
}

// 默认配置
const defaultOptions: Required<ProgressOptions> = {
    max: 100,
    color: 'neutral'
}

// 创建一个全局状态
const state = ref<ProgressState>({
    show: false,
    value: undefined,
    ...defaultOptions
})

/**
 * Progress 进度条 Composable
 * 提供全局进度条功能
 */
export function useProgress() {
    /**
     * 开始显示进度条
     * @param initialValue 初始进度值，不传则显示不确定进度动画
     * @param options 配置选项
     */
    const start = (initialValue?: number, options: ProgressOptions = {}) => {
        state.value = {
            show: true,
            value: initialValue,
            ...defaultOptions,
            ...options
        }
    }

    /**
     * 更新进度值
     * @param value 新的进度值
     */
    const update = (value: number) => {
        if (state.value.show) {
            state.value.value = value
        }
    }

    /**
     * 完成进度并隐藏进度条
     * 会先将进度更新到100%，然后短暂延迟后隐藏
     */
    const finish = () => {
        if (state.value.show) {
            state.value.value = state.value.max
            setTimeout(() => {
                state.value.show = false
            }, 200)
        }
    }

    /**
     * 直接隐藏进度条
     */
    const hide = () => {
        state.value.show = false
    }

    return {
        state,
        start,
        update,
        finish,
        hide
    }
}

// 创建一个全局实例
export const globalProgress = useProgress()
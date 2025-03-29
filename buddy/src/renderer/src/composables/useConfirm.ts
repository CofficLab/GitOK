import { ref } from 'vue'

// 确认对话框状态
interface ConfirmState {
  show: boolean
  title: string
  message: string
  confirmText: string
  cancelText: string
  confirmVariant: 'default' | 'primary' | 'secondary' | 'accent' | 'ghost'
  cancelVariant: 'default' | 'primary' | 'secondary' | 'accent' | 'ghost'
  loading: boolean
  resolve: ((value: boolean) => void) | null
}

// 默认配置
const defaultOptions = {
  title: '',
  message: '',
  confirmText: '确认',
  cancelText: '取消',
  confirmVariant: 'primary' as const,
  cancelVariant: 'ghost' as const,
}

// 创建一个全局状态
const state = ref<ConfirmState>({
  show: false,
  ...defaultOptions,
  loading: false,
  resolve: null,
})

/**
 * 确认对话框 Composable
 * 提供全局确认对话框功能
 */
export function useConfirm() {
  /**
   * 显示确认对话框
   * @param options 配置选项
   * @returns Promise，用户确认返回 true，取消返回 false
   */
  const confirm = (options: Partial<Omit<ConfirmState, 'show' | 'resolve' | 'loading'>> = {}) => {
    return new Promise<boolean>((resolve) => {
      state.value = {
        ...state.value,
        ...defaultOptions,
        ...options,
        show: true,
        loading: false,
        resolve,
      }
    })
  }

  /**
   * 处理确认操作
   */
  const handleConfirm = async () => {
    try {
      state.value.loading = true
      if (state.value.resolve) {
        state.value.resolve(true)
      }
    } finally {
      // 延迟关闭以便显示加载状态
      setTimeout(() => {
        state.value.show = false
        state.value.loading = false
      }, 300)
    }
  }

  /**
   * 处理取消操作
   */
  const handleCancel = () => {
    if (state.value.resolve) {
      state.value.resolve(false)
    }
    state.value.show = false
  }

  return {
    // 状态
    state,
    // 方法
    confirm,
    handleConfirm,
    handleCancel,
  }
}

// 创建一个全局实例
export const globalConfirm = useConfirm()

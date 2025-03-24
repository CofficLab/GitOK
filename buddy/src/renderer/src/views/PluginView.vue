/**
* 插件动作视图
*
* 功能：
* 1. 展示选中的插件动作详情
* 2. 显示动作执行结果或在独立的BrowserWindow中显示自定义视图
* 3. 提供返回到动作列表的功能
*/
<script setup lang="ts">
import { PluginAction } from '@/types/plugin-action';
import { ref, watch, onUnmounted, reactive, onMounted } from 'vue'
import { usePluginManager } from '@renderer/composables/usePluginManager';
import { useSearchStore } from '@renderer/stores/searchStore'

const pluginManager = usePluginManager()
const searchStore = useSearchStore()

// 定义辅助函数获取插件视图API
const getPluginViewsAPI = () => {
    try {
        const api = (window.electron.plugins as any).views;
        // 检查所需API是否都存在
        if (!api || !api.create || !api.show || !api.destroy) {
            console.error('PluginView: 获取插件视图API失败，API不完整');
            return null;
        }
        return api;
    } catch (error) {
        console.error('PluginView: 获取插件视图API失败', error);
        return null;
    }
}

const emit = defineEmits<{
    back: []
}>()

// 当前选中的动作
const selectedAction = ref<PluginAction | null>(null)
// 是否正在加载动作视图
const isLoading = ref(false)
// 动作执行的结果
const actionResult = ref<any>(null)
// 是否发生错误
const hasError = ref(false)
// 错误信息
const errorMessage = ref('')
// 插件视图窗口状态
const pluginViewState = reactive({
    id: '',
    isOpen: false
})
// 内嵌视图状态
const embeddedViewState = reactive({
    id: '',
    isAttached: false,
    isVisible: false,
    content: ''
})
// 嵌入式视图容器引用
const embeddedViewContainer = ref<HTMLDivElement | null>(null)

// 加载并执行动作
const loadAndExecuteAction = async () => {
    const actionId = searchStore.selectedActionId
    if (!actionId) return

    isLoading.value = true
    hasError.value = false
    errorMessage.value = ''
    actionResult.value = null

    // 如果有之前打开的视图，关闭它
    await closePluginWindow()
    await destroyEmbeddedView()

    try {
        // 查找动作信息
        const action = pluginManager.getAction(actionId, 'loadAndExecuteAction')
        if (!action) {
            throw new Error(`未找到动作: ${actionId}`)
        }

        selectedAction.value = action
        console.log(`PluginView: 加载动作 ${action.title}`)

        // 执行动作
        const result = await pluginManager.executeAction(action)
        actionResult.value = result
        console.log(`PluginView: 动作执行结果:`, result)

        // 如果有视图路径，根据viewMode决定显示方式
        if (action.viewPath) {
            console.log(`PluginView: 动作有视图路径: ${action.viewPath}, 视图模式: ${action.viewMode || 'embedded'}`)
            const viewMode = action.viewMode || 'embedded' // 默认使用内嵌模式

            if (viewMode === 'window') {
                // 在独立窗口中显示
                console.log(`PluginView: 使用独立窗口模式显示`)
                await openPluginWindow(actionId, action)
            } else {
                // 在应用内嵌入显示
                console.log(`PluginView: 使用内嵌模式显示`)
                await createEmbeddedView(actionId, action)
            }
        } else {
            console.log(`PluginView: 动作没有视图路径，只显示结果`)
        }
    } catch (error) {
        const errorMsg = error instanceof Error ? error.message : String(error)
        console.error(`PluginView: 执行动作失败: ${errorMsg}`)
        hasError.value = true
        errorMessage.value = errorMsg
    } finally {
        isLoading.value = false
    }
}

// 创建并显示嵌入式视图
const createEmbeddedView = async (actionId: string, action: PluginAction) => {
    try {
        // 使用动作ID作为视图ID
        embeddedViewState.id = `embedded-view-${actionId}`

        // 获取插件视图API
        const viewsAPI = getPluginViewsAPI()
        if (!viewsAPI) {
            throw new Error('插件视图API不可用')
        }

        // 获取主进程存储的HTML内容
        if (!pluginManager) {
            throw new Error('插件管理器未初始化')
        }
        embeddedViewState.content = pluginManager.actionViewHtml
        console.log(`PluginView: 获取到视图HTML内容，长度: ${embeddedViewState.content?.length || 0}`)

        // 清除可能存在的错误状态，确保条件渲染逻辑正确
        hasError.value = false
        errorMessage.value = ''
        isLoading.value = false

        // 首先将视图状态设置为已附加，这样模板会渲染出容器
        embeddedViewState.isAttached = true
        console.log('PluginView: 设置视图状态为已附加，准备渲染容器...')

        // 等待下一个渲染周期完成
        await nextTick()

        // 增加一个小延迟，让DOM有足够时间渲染
        await new Promise(resolve => setTimeout(resolve, 50));

        // 等待DOM完全渲染
        // 增加一个循环来确保容器已渲染，最多尝试10次，每次等待100ms
        let attempts = 0;
        const maxAttempts = 20; // 增加最大尝试次数
        while (!embeddedViewContainer.value && attempts < maxAttempts) {
            await new Promise(resolve => setTimeout(resolve, 50)); // 减少等待时间，增加频率
            attempts++;
            console.log(`PluginView: 等待容器渲染，尝试 ${attempts}/${maxAttempts}`);
            // 强制刷新一下DOM引用
            await nextTick();
        }

        // 确保容器已渲染
        if (!embeddedViewContainer.value) {
            console.error('PluginView: 视图容器不存在，无法创建视图');
            throw new Error('嵌入式视图容器不存在');
        }

        console.log('PluginView: 容器已渲染，准备创建嵌入式视图');

        // 获取容器位置和尺寸
        const container = embeddedViewContainer.value
        const rect = container.getBoundingClientRect()

        // 确保所有值都是整数，并且至少有合理的尺寸
        const bounds = {
            x: Math.max(0, Math.round(rect.left)),
            y: Math.max(0, Math.round(rect.top)),
            width: Math.max(100, Math.round(rect.width)),
            height: Math.max(100, Math.round(rect.height))
        }

        console.log(`PluginView: 创建嵌入式视图: ${embeddedViewState.id}，容器边界:`, bounds)

        try {
            // 首先创建嵌入式视图
            const mainWindowBounds = await viewsAPI.create(
                embeddedViewState.id,
                `plugin-view://${actionId}`,
                'embedded'
            )

            console.log('PluginView: 嵌入式视图已创建，主窗口边界:', mainWindowBounds)

            // 现在显示嵌入式视图，传递容器边界
            const showResult = await viewsAPI.show(embeddedViewState.id, bounds)
            if (!showResult) {
                throw new Error('显示嵌入式视图失败')
            }

            console.log(`PluginView: 嵌入式视图已显示，边界:`, bounds)
            embeddedViewState.isVisible = true

            // 立即触发一次调整大小操作，确保视图正确显示
            await handleResize()

            // 添加窗口尺寸变化时的视图调整逻辑
            setTimeout(async () => {
                await handleResize()
            }, 500)

            // 如果动作指定了开启开发者工具，则自动打开
            if (action.devTools) {
                setTimeout(async () => {
                    try {
                        console.log(`PluginView: 准备打开开发者工具: ${embeddedViewState.id}`)
                        const result = await viewsAPI.toggleDevTools(embeddedViewState.id)
                        console.log(`PluginView: 开发者工具打开结果: ${result}`)
                    } catch (devToolsError) {
                        console.error(`PluginView: 打开开发者工具失败:`, devToolsError)
                    }
                }, 1000)
            }
        } catch (viewError) {
            // 处理视图创建或显示过程中的错误
            console.error(`PluginView: 视图操作失败:`, viewError);
            throw viewError;
        }
    } catch (error) {
        const errorMsg = error instanceof Error ? error.message : String(error)
        console.error(`PluginView: 创建嵌入式视图失败: ${errorMsg}`)

        // 重置视图状态
        embeddedViewState.isAttached = false
        embeddedViewState.isVisible = false

        hasError.value = true
        errorMessage.value = `创建嵌入式视图失败: ${errorMsg}`
    }
}

// 销毁嵌入式视图
const destroyEmbeddedView = async () => {
    if (embeddedViewState.id) {
        try {
            const viewsAPI = getPluginViewsAPI()
            if (viewsAPI) {
                await viewsAPI.destroy(embeddedViewState.id)
                console.log(`PluginView: 嵌入式视图已销毁: ${embeddedViewState.id}`)
            }
        } catch (error) {
            console.error(`PluginView: 销毁嵌入式视图失败:`, error)
        } finally {
            embeddedViewState.id = ''
            embeddedViewState.isAttached = false
            embeddedViewState.isVisible = false
            embeddedViewState.content = ''
        }
    }
}

// 在独立窗口中打开插件视图
const openPluginWindow = async (actionId: string, action: PluginAction) => {
    try {
        // 使用动作ID作为视图ID
        pluginViewState.id = `plugin-view-${actionId}`

        // 获取插件视图API
        const viewsAPI = getPluginViewsAPI()
        if (!viewsAPI) {
            throw new Error('插件视图API不可用')
        }

        // 获取主窗口位置和大小以便设置插件窗口的位置
        const mainWindowBounds = await viewsAPI.create(
            pluginViewState.id,
            `plugin-view://${actionId}`, // 确保actionId格式正确
            'window' // 视图模式
        )

        if (mainWindowBounds) {
            // 在主窗口旁边显示插件窗口
            await viewsAPI.show(pluginViewState.id, {
                x: mainWindowBounds.x + mainWindowBounds.width,
                y: mainWindowBounds.y,
                width: 600,
                height: mainWindowBounds.height
            })

            pluginViewState.isOpen = true
            console.log(`PluginView: 插件视图窗口已打开: ${pluginViewState.id}`)

            // 如果动作指定了开启开发者工具，则自动打开
            if (action.devTools) {
                console.log(`PluginView: 动作指定了开启开发者工具，准备打开: ${actionId}`)
                try {
                    // 设置一个定时器，延迟500ms打开开发者工具
                    setTimeout(async () => {
                        console.log(`PluginView: 准备打开开发者工具: ${pluginViewState.id}`)
                        const result = await viewsAPI.toggleDevTools(pluginViewState.id)
                        console.log(`PluginView: 开发者工具打开结果: ${result}`)
                    }, 500)
                } catch (devToolsError) {
                    console.error(`PluginView: 打开开发者工具失败:`, devToolsError)
                }
            }
        }
    } catch (error) {
        const errorMsg = error instanceof Error ? error.message : String(error)
        console.error(`PluginView: 打开插件视图窗口失败: ${errorMsg}`)
        hasError.value = true
        errorMessage.value = `打开插件视图失败: ${errorMsg}`
    }
}

// 关闭插件视图窗口
const closePluginWindow = async () => {
    if (pluginViewState.isOpen && pluginViewState.id) {
        try {
            const viewsAPI = getPluginViewsAPI()
            if (viewsAPI) {
                await viewsAPI.destroy(pluginViewState.id)
                console.log(`PluginView: 插件视图窗口已关闭: ${pluginViewState.id}`)
            }
        } catch (error) {
            console.error(`PluginView: 关闭插件视图窗口失败:`, error)
        } finally {
            pluginViewState.isOpen = false
            pluginViewState.id = ''
        }
    }
}

// 返回动作列表
const goBack = async () => {
    // 关闭所有视图
    await closePluginWindow()
    await destroyEmbeddedView()
    emit('back')
}

// 设置嵌入式视图事件监听器的清理函数
const cleanupFunctions: (() => void)[] = [];

// 监听嵌入式视图创建事件
const setupEmbeddedViewEventListeners = () => {
    const pluginViewsAPI = getPluginViewsAPI();

    // 如果API不存在或不完整，不设置事件监听器
    if (!pluginViewsAPI) {
        console.warn('PluginView: 插件视图API不可用，无法设置事件监听器');
        return;
    }

    // 检查事件监听器函数是否存在
    if (typeof pluginViewsAPI.onEmbeddedViewCreated === 'function') {
        const removeCreatedListener = pluginViewsAPI.onEmbeddedViewCreated((data) => {
            console.log(`PluginView: 收到嵌入式视图创建事件: ${data.viewId}`);
        });
        cleanupFunctions.push(removeCreatedListener);
    } else {
        console.warn('PluginView: onEmbeddedViewCreated 方法不存在');
    }

    // 检查事件监听器函数是否存在
    if (typeof pluginViewsAPI.onShowEmbeddedView === 'function') {
        const removeShowListener = pluginViewsAPI.onShowEmbeddedView((data) => {
            console.log(`PluginView: 收到显示嵌入式视图事件: ${data.viewId}`);
            // 标记视图为可见
            if (embeddedViewState.id === data.viewId) {
                embeddedViewState.isVisible = true;
            }
        });
        cleanupFunctions.push(removeShowListener);
    } else {
        console.warn('PluginView: onShowEmbeddedView 方法不存在');
    }

    // 检查事件监听器函数是否存在
    if (typeof pluginViewsAPI.onHideEmbeddedView === 'function') {
        const removeHideListener = pluginViewsAPI.onHideEmbeddedView((data) => {
            console.log(`PluginView: 收到隐藏嵌入式视图事件: ${data.viewId}`);
            // 标记视图为不可见
            if (embeddedViewState.id === data.viewId) {
                embeddedViewState.isVisible = false;
            }
        });
        cleanupFunctions.push(removeHideListener);
    } else {
        console.warn('PluginView: onHideEmbeddedView 方法不存在');
    }

    // 检查事件监听器函数是否存在
    if (typeof pluginViewsAPI.onDestroyEmbeddedView === 'function') {
        const removeDestroyListener = pluginViewsAPI.onDestroyEmbeddedView((data) => {
            console.log(`PluginView: 收到销毁嵌入式视图事件: ${data.viewId}`);
            // 重置视图状态
            if (embeddedViewState.id === data.viewId) {
                embeddedViewState.id = '';
                embeddedViewState.isAttached = false;
                embeddedViewState.isVisible = false;
                embeddedViewState.content = '';
            }
        });
        cleanupFunctions.push(removeDestroyListener);
    } else {
        console.warn('PluginView: onDestroyEmbeddedView 方法不存在');
    }
};

// 在窗口大小变化时调整嵌入式视图大小
const handleResize = async () => {
    if (embeddedViewState.isAttached && embeddedViewState.id && embeddedViewContainer.value) {
        const viewsAPI = getPluginViewsAPI();
        if (!viewsAPI) {
            console.warn('PluginView: 获取视图API失败，无法调整视图大小');
            return;
        }

        try {
            const container = embeddedViewContainer.value;
            const rect = container.getBoundingClientRect();

            // 确保边界值有效且是整数
            const bounds = {
                x: Math.max(0, Math.round(rect.left)),
                y: Math.max(0, Math.round(rect.top)),
                width: Math.max(100, Math.round(rect.width)),
                height: Math.max(100, Math.round(rect.height))
            };

            // 检查边界值是否有效
            if (bounds.width <= 0 || bounds.height <= 0) {
                console.warn(`PluginView: 容器边界无效，宽高必须大于0: `, bounds);
                return;
            }

            console.log(`PluginView: 调整嵌入式视图大小: ${embeddedViewState.id}`, bounds);

            const result = await viewsAPI.show(embeddedViewState.id, bounds);
            console.log(`PluginView: 调整视图大小结果: ${result}`);
        } catch (error) {
            console.error(`PluginView: 调整视图大小失败:`, error);
        }
    } else {
        if (!embeddedViewState.isAttached) {
            console.debug('PluginView: 视图未附加，跳过调整大小');
        } else if (!embeddedViewState.id) {
            console.debug('PluginView: 视图ID为空，跳过调整大小');
        } else if (!embeddedViewContainer.value) {
            console.debug('PluginView: 视图容器不存在，跳过调整大小');
        }
    }
};

// 添加窗口调整大小事件监听器
const setupResizeListener = () => {
    // 使用防抖函数来避免频繁调用
    let resizeTimeout: number | null = null;

    const debouncedResize = () => {
        if (resizeTimeout !== null) {
            clearTimeout(resizeTimeout);
        }
        resizeTimeout = window.setTimeout(async () => {
            await handleResize();
            resizeTimeout = null;
        }, 100);
    };

    window.addEventListener('resize', debouncedResize);

    // 返回清理函数
    return () => {
        if (resizeTimeout !== null) {
            clearTimeout(resizeTimeout);
        }
        window.removeEventListener('resize', debouncedResize);
    };
};

// 设置嵌入式视图事件监听器
setupEmbeddedViewEventListeners();

// 设置调整大小事件监听器并保存清理函数
cleanupFunctions.push(setupResizeListener());

// 在组件卸载时清理所有事件监听器
onUnmounted(() => {
    console.log('PluginView: 组件卸载，清理事件监听器');

    // 销毁嵌入式视图
    destroyEmbeddedView();

    // 清理所有监听器
    cleanupFunctions.forEach(cleanup => {
        try {
            cleanup();
        } catch (error) {
            console.error('PluginView: 清理事件监听器失败:', error);
        }
    });

    // 清空数组
    cleanupFunctions.length = 0;
});

// 导入nextTick用于等待DOM更新
import { nextTick } from 'vue'

// 在动作ID变化时重新加载
watch(() => searchStore.selectedActionId, (newId) => {
    if (newId) {
        loadAndExecuteAction()
    }
})

// 组件挂载时加载动作
onMounted(() => {
    const actionId = searchStore.selectedActionId
    if (actionId) {
        loadAndExecuteAction()
    }
})
</script>

<template>
    <div class="plugin-view flex flex-col h-full">
        <!-- 头部 - 标题和返回按钮 -->
        <div class="flex items-center mb-4">
            <button @click="goBack" class="flex items-center text-blue-500 hover:text-blue-700">
                <span class="mr-1">←</span> 返回
            </button>
            <h2 v-if="selectedAction" class="text-xl font-semibold ml-4">{{ selectedAction.title }}</h2>
        </div>

        <!-- 加载中状态 -->
        <div v-if="isLoading" class="flex-1 flex items-center justify-center">
            <p class="text-gray-500">加载中...</p>
        </div>

        <!-- 错误状态 -->
        <div v-else-if="hasError" class="error flex-1 p-4">
            <h3 class="text-red-600 font-medium mb-2">执行动作失败</h3>
            <p>{{ errorMessage }}</p>
        </div>

        <!-- 内嵌视图容器 - 始终存在但仅在需要时显示 -->
        <div ref="embeddedViewContainer"
            class="flex-1 border rounded-lg bg-white shadow-sm overflow-hidden embedded-view-container"
            :class="{ 'hidden': !embeddedViewState.isAttached }"
            style="min-height: 400px; position: relative; z-index: 1;">
            <div class="debug-info p-4 text-xs text-gray-500">
                <div><strong>视图信息:</strong> {{ selectedAction?.title }} ({{ selectedAction?.id }})</div>
                <div><strong>视图模式:</strong> 内嵌式BrowserView</div>
                <div><strong>视图ID:</strong> {{ embeddedViewState.id }}</div>
                <div v-if="embeddedViewState.isVisible"><strong>状态:</strong> 可见</div>
                <div v-else><strong>状态:</strong> 正在加载...</div>
            </div>
        </div>

        <!-- 插件使用独立窗口显示 -->
        <div v-if="!embeddedViewState.isAttached && pluginViewState.isOpen"
            class="flex-1 flex flex-col items-center justify-center p-6 border rounded-lg border-blue-200 bg-blue-50">
            <p class="text-lg mb-4">插件视图已在独立窗口中打开</p>
            <p class="text-sm text-gray-600 mb-6">该窗口将在您返回动作列表或关闭此页面时自动关闭</p>
            <button @click="closePluginWindow"
                class="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 transition">
                关闭插件窗口
            </button>
        </div>

        <!-- 显示结果（如果没有视图） -->
        <div v-if="!embeddedViewState.isAttached && !pluginViewState.isOpen && actionResult"
            class="flex-1 p-4 border rounded-lg bg-gray-50 overflow-auto">
            <pre class="whitespace-pre-wrap">{{ JSON.stringify(actionResult, null, 2) }}</pre>
        </div>

        <!-- 空状态 -->
        <div v-if="!embeddedViewState.isAttached && !pluginViewState.isOpen && !actionResult && !isLoading && !hasError"
            class="flex-1 flex items-center justify-center text-gray-500">
            <p>未加载任何动作</p>
        </div>
    </div>
</template>

<style scoped>
.error {
    color: #e53e3e;
    padding: 1rem;
    border: 1px solid #feb2b2;
    border-radius: 0.5rem;
    background-color: #fff5f5;
}

.embedded-view-container {
    display: flex;
    flex-direction: column;
    min-height: 400px;
    position: relative;
    z-index: 1;
}

.embedded-view-container.hidden {
    display: none;
}

/* 在调试信息下方预留空间，让实际内容区域不被遮挡 */
.embedded-view-container .debug-info {
    position: relative;
    z-index: 10;
    background-color: rgba(255, 255, 255, 0.8);
    border-bottom: 1px solid #eee;
    padding: 12px;
}
</style>
<!--
App.vue - 应用程序入口组件

这是应用的根组件，主要负责：
1. 组织整体布局结构（使用MainLayout组件）
2. 管理插件系统的生命周期
3. 处理插件消息通信
4. 管理全局快捷键

技术栈：
- Vue 3 组合式API
- Pinia 状态管理
- Electron IPC通信

注意事项：
- 所有的状态管理都通过pinia store处理
- 插件通信使用electron的IPC机制
- 组件间通过store而不是props通信
-->

<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch } from 'vue'
import SearchBar from './layouts/SearchBar.vue'
import PluginManager from './components/PluginManager.vue'
import { useSearchStore } from './stores/searchStore'
import MainLayout from './layouts/MainLayout.vue'
import ContentView from './layouts/ContentView.vue'

// PluginManager组件引用
const pluginManager = ref()
// SearchBar组件引用
const searchBar = ref()

// 使用搜索store
const searchStore = useSearchStore()

// 处理从插件视图接收的消息
const handlePluginMessage = (...args: unknown[]) => {
    const message = args[1] as { viewId: string, channel: string, data: any };

    console.log(`收到插件消息 - 视图ID: ${message.viewId}, 频道: ${message.channel}`, message.data)

    // 根据消息类型处理不同的操作
    switch (message.channel) {
        case 'close':
            searchStore.clearSelectedAction()
            break
        case 'execute-action':
            if (message.data?.actionId && pluginManager.value) {
                pluginManager.value.executeAction(message.data.actionId)
            }
            break
        // 可以根据需要添加更多消息类型处理
    }
}

// 处理插件视图请求关闭
const handlePluginCloseRequest = (...args: unknown[]) => {
    const message = args[1] as { viewId: string };

    console.log(`插件视图请求关闭: ${message.viewId}`)
    searchStore.clearSelectedAction()
}

// 处理全局键盘事件
const handleGlobalKeyDown = (event: KeyboardEvent) => {
    // 如果用户按下斜杠(/)键，聚焦搜索框
    if (event.key === '/' && !isInputElement(event.target as HTMLElement)) {
        event.preventDefault()
        focusSearchBar()
    }

    // 如果用户按下Ctrl+K或Cmd+K，聚焦搜索框
    if ((event.ctrlKey || event.metaKey) && event.key === 'k') {
        event.preventDefault()
        focusSearchBar()
    }
}

// 检查元素是否为输入元素
const isInputElement = (element: HTMLElement | null): boolean => {
    if (!element) return false

    const tagName = element.tagName.toLowerCase()
    return tagName === 'input' ||
        tagName === 'textarea' ||
        element.isContentEditable
}

// 聚焦搜索框
const focusSearchBar = () => {
    if (searchBar.value?.focus) {
        searchBar.value.focus()
    }
}

// 手动测试API调用 - 直接调用获取插件动作
const testGetPluginActions = async () => {
    console.log('APP: 手动测试 getPluginActions API...');
    try {
        const response = await window.api.plugins.getPluginActions('计算器');
        console.log('APP: API响应:', response);

        // 分析响应格式
        if (Array.isArray(response)) {
            console.log('APP: 响应是数组格式，长度:', response.length);
        } else if (response && typeof response === 'object') {
            console.log('APP: 响应是对象格式:', Object.keys(response));
            if ('success' in response) {
                console.log('APP: success 字段值:', response.success);
            }
            if ('actions' in response) {
                console.log('APP: actions 字段是数组?', Array.isArray(response.actions));
                console.log('APP: actions 长度:', response.actions?.length || 0);
            }
        }
    } catch (error) {
        console.error('APP: API调用失败:', error);
    }
}

// 在组件加载时注册消息监听和初始化
onMounted(() => {
    // 注册接收插件消息的处理函数
    window.api.receive('plugin-message', handlePluginMessage)
    // 注册插件视图请求关闭的处理函数
    window.api.receive('plugin-close-requested', handlePluginCloseRequest)

    // 注册全局键盘事件
    document.addEventListener('keydown', handleGlobalKeyDown)

    // 初始加载插件动作
    searchStore.loadPluginActions()

    // 初始聚焦搜索框
    setTimeout(focusSearchBar, 300)

    // 延迟1秒后执行API测试
    setTimeout(testGetPluginActions, 1000);
})

// 在组件卸载时清理消息监听
onUnmounted(() => {
    // 移除消息监听
    window.api.removeListener('plugin-message', handlePluginMessage)
    window.api.removeListener('plugin-close-requested', handlePluginCloseRequest)

    // 移除全局键盘事件
    document.removeEventListener('keydown', handleGlobalKeyDown)
})

// 监听搜索输入变化，加载相应的插件动作
watch(() => searchStore.keyword, async (newKeyword) => {
    console.log(`App.vue: 搜索关键词变化为 "${newKeyword}"`);

    // 重新加载插件动作
    try {
        console.log('App.vue: 开始加载插件动作...');
        await searchStore.loadPluginActions();
        console.log(`App.vue: 插件动作加载完成，共 ${searchStore.pluginActions.length} 个`);

        // 如果有关键词但没有动作，重试一次
        if (newKeyword && searchStore.pluginActions.length === 0) {
            console.log('App.vue: 检测到有关键词但没有动作，延迟1秒重试...');
            setTimeout(async () => {
                await searchStore.loadPluginActions();
                console.log(`App.vue: 重试加载完成，共 ${searchStore.pluginActions.length} 个动作`);
            }, 1000);
        }
    } catch (error) {
        console.error('App.vue: 加载插件动作失败', error);
    }
}, { immediate: true })
</script>

<template>
    <!-- 插件管理器包装整个应用，提供依赖注入 -->
    <PluginManager ref="pluginManager">
        <MainLayout>
            <!-- 搜索区域 -->
            <template #search>
                <SearchBar ref="searchBar" class="search-container" />
            </template>

            <!-- 内容区域 -->
            <template #content>
                <ContentView />
            </template>
        </MainLayout>
    </PluginManager>
</template>
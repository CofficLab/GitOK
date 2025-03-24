<!--
ContentView.vue - 内容视图组件

这是应用的内容管理组件，负责：
1. 管理不同内容视图的切换逻辑
2. 内容区域的显示和导航
3. 根据当前视图状态显示不同内容

状态管理：
- 使用appStore管理视图状态
- 使用searchStore管理搜索相关状态

视图切换逻辑：
1. 默认显示首页或动作列表视图
2. 选中动作后委托给PluginView组件处理
3. 打开插件商店时显示商店界面

技术栈：
- Vue 3 组合式API
- Pinia 状态管理
- TailwindCSS 样式

注意事项：
- 视图逻辑解耦，各自负责自己的职责
- 使用store驱动的状态管理降低组件间耦合
-->

<script setup lang="ts">
import { computed, onMounted, watch } from 'vue'
import { useAppStore } from '@renderer/stores/appStore'
import { useSearchStore } from '@renderer/stores/searchStore'
import { HomeView, PluginView, ActionListView, PluginStoreView } from '@renderer/views'

const appStore = useAppStore()
const searchStore = useSearchStore()
const currentView = computed(() => appStore.currentView)

// 处理返回到动作列表
const handleBackToList = () => {
    searchStore.clearSelectedAction()
}

// 判断是否应该显示动作列表
const shouldShowActionList = computed(() => {
    const hasActions = searchStore.pluginActions.length > 0;
    const hasKeyword = searchStore.keyword.length > 0;
    const result = hasActions || hasKeyword;

    console.log(`ContentView: shouldShowActionList = ${result}`, {
        pluginActionsLength: searchStore.pluginActions.length,
        keyword: searchStore.keyword,
        hasActions,
        hasKeyword,
        selectedActionId: searchStore.selectedActionId,
        isLoading: searchStore.isLoading
    });

    return result;
})

// 为了调试在搜索时观察 shouldShowActionList 的变化
watch(() => searchStore.keyword, (newKeyword) => {
    console.log(`ContentView: 搜索关键词变化为 "${newKeyword}"`);

    // 延迟一下检查 pluginActions
    setTimeout(() => {
        console.log(`ContentView: 延迟检查，当前有 ${searchStore.pluginActions.length} 个动作`);
        console.log(`ContentView: shouldShowActionList = ${shouldShowActionList.value}`);
    }, 500);
})

// 为了调试在动作列表变化时观察
watch(() => searchStore.pluginActions, (newActions) => {
    console.log(`ContentView: 动作列表更新，现在有 ${newActions.length} 个动作`);
    console.log(`ContentView: shouldShowActionList = ${shouldShowActionList.value}`);
}, { deep: true })

// 添加组件挂载时的日志
onMounted(() => {
    console.log('ContentView 挂载完成');
    console.log('初始状态:', {
        currentView: appStore.currentView,
        pluginActions: searchStore.pluginActions.length,
        keyword: searchStore.keyword,
        isLoading: searchStore.isLoading
    });
})
</script>

<template>
    <div class="flex-1 overflow-auto p-4">
        <!-- 首页视图 -->
        <div v-if="currentView === 'home'" class="space-y-4">
            <!-- 显示HomeView内容（当没有搜索关键词且没有插件动作时） -->
            <HomeView v-if="!shouldShowActionList && !searchStore.selectedActionId" />

            <!-- 插件动作列表（当有搜索关键词或有插件动作时） -->
            <ActionListView v-else-if="!searchStore.selectedActionId" />

            <!-- 插件动作视图 -->
            <PluginView v-else :action-id="searchStore.selectedActionId" @back="handleBackToList" />
        </div>

        <!-- 插件商店视图 -->
        <PluginStoreView v-else-if="currentView === 'plugins'" />
    </div>
</template>

<style scoped>
.error {
    color: red;
    padding: 1rem;
    border: 1px solid red;
    border-radius: 0.5rem;
    background-color: rgba(255, 0, 0, 0.1);
}
</style>
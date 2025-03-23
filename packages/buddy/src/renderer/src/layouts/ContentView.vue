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
1. 默认显示插件动作列表
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
import { ref, computed, inject, onMounted, watch } from 'vue'
import { useAppStore } from '@renderer/stores/appStore'
import { useSearchStore } from '@renderer/stores/searchStore'
import PluginActionList from '@renderer/components/PluginActionList.vue'
import PluginView from '@renderer/views/PluginView.vue'
import type { PluginManagerAPI, PluginAction } from '@renderer/components/PluginManager.vue'

const appStore = useAppStore()
const searchStore = useSearchStore()
const currentView = computed(() => appStore.currentView)

// 插件管理器API
const pluginManager = inject<PluginManagerAPI>('pluginManager')

// 处理动作选择
const handleActionSelected = (action: PluginAction) => {
    searchStore.selectAction(action.id)
}

// 处理返回到动作列表
const handleBackToList = () => {
    searchStore.clearSelectedAction()
}

// 组件挂载时的初始化
onMounted(() => {
    console.log('ContentView 已挂载')
    console.log(`当前搜索框状态: keyword=${searchStore.keyword}, actions=${searchStore.pluginActions.length}`)

    // 初始化时加载插件动作
    if (searchStore.pluginActions.length === 0 && !searchStore.isLoading) {
        searchStore.loadPluginActions()
    }
})
</script>

<template>
    <div class="flex-1 overflow-auto p-4">
        <!-- 首页视图 -->
        <div v-if="currentView === 'home'" class="space-y-4">
            <h1 class="text-2xl font-bold">欢迎使用 GitOK</h1>
            <p class="text-gray-600">这是一个强大的 Git 工具，帮助你更好地管理代码。</p>

            <!-- 插件动作列表 -->
            <div v-if="!searchStore.selectedActionId" class="mt-8">
                <h2 class="text-xl font-semibold mb-4">可用动作</h2>
                <PluginActionList :actions="searchStore.pluginActions" :loading="searchStore.isLoading"
                    @select="handleActionSelected" />
            </div>

            <!-- 插件动作视图 -->
            <PluginView v-else :action-id="searchStore.selectedActionId" @back="handleBackToList" />
        </div>

        <!-- 插件管理视图 -->
        <component :is="currentView === 'plugins' ? 'PluginManager' : 'div'" />
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
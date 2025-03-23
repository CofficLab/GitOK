<!--
ContentView.vue - 内容视图组件

这是应用的内容管理组件，负责：
1. 管理不同内容视图的切换逻辑
2. 处理三种主要视图的显示：
   - 插件动作列表（默认视图）
   - 动作详情视图
   - 插件商店视图
3. 处理视图间的切换动作

状态管理：
- 使用appStore管理视图状态
- 使用searchStore管理搜索相关状态

视图切换逻辑：
1. 默认显示插件动作列表
2. 选中动作后显示动作详情
3. 打开插件商店时显示商店界面
4. 返回按钮可以回到动作列表

技术栈：
- Vue 3 组合式API
- Pinia 状态管理
- TailwindCSS 样式

注意事项：
- 所有状态通过store管理，组件只负责渲染
- 视图切换时注意状态的正确清理
- 动作执行时需要考虑异步处理

这个组件负责管理内容区域的显示：
1. 首页视图
2. 插件管理视图

主要功能：
- 根据当前视图状态显示不同内容
- 管理视图之间的切换

技术栈：
- Vue 3
- Pinia (appStore)
- TailwindCSS

注意事项：
- 通过 appStore 管理视图状态
- 保持视图切换的流畅性
-->

<script setup lang="ts">
import { computed } from 'vue'
import { useAppStore } from '@renderer/stores/appStore'
import PluginManager from '@renderer/components/PluginManager.vue'

const appStore = useAppStore()
const currentView = computed(() => appStore.currentView)
</script>

<template>
    <div class="flex-1 overflow-auto p-4">
        <!-- 首页视图 -->
        <div v-if="currentView === 'home'" class="space-y-4">
            <h1 class="text-2xl font-bold">欢迎使用 GitOK</h1>
            <p class="text-gray-600">这是一个强大的 Git 工具，帮助你更好地管理代码。</p>
        </div>

        <!-- 插件管理视图 -->
        <PluginManager v-else-if="currentView === 'plugins'" />
    </div>
</template>
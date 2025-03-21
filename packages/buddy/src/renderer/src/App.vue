<script setup lang="ts">
import { ref, onMounted, reactive } from "vue"
import Versions from "./components/Versions.vue"
import TitleBar from "./components/TitleBar.vue"
import PluginView from "./components/plugins/PluginView.vue"
import PluginManager from "./components/PluginManager.vue"
import { BuddyPluginViewInfo } from "./types/plugins"
import "./app.css"

// 活动标签页
const activeTab = ref("home")

// 侧边栏菜单项
const sidebarItems = [
    { id: 'home', name: '首页', icon: 'i-mdi-home' },
    { id: 'plugins', name: '插件管理', icon: 'i-mdi-puzzle' },
    // 可以添加更多菜单项
]

// 是否展开侧边栏
const sidebarExpanded = ref(true)

// 切换侧边栏展开/收起状态
function toggleSidebar() {
    sidebarExpanded.value = !sidebarExpanded.value
}

// 插件视图
const pluginViews = reactive<BuddyPluginViewInfo[]>([])

// 加载插件视图
onMounted(async () => {
    try {
        const views = await window.api.plugins.getViews()
        pluginViews.push(...views)
    } catch (error) {
        console.error("加载插件视图失败:", error)
    }
})
</script>

<template>
    <TitleBar />
    <div class="mt-[38px] h-[calc(100vh-38px)] flex overflow-hidden">
        <!-- 左侧侧边栏 -->
        <div :class="[
            'bg-neutral-800 text-neutral-300 flex flex-col overflow-y-auto transition-all duration-200',
            sidebarExpanded ? 'w-60' : 'w-12'
        ]">
            <!-- 侧边栏顶部图标 -->
            <div class="h-12 flex items-center justify-center border-b border-neutral-700">
                <a @click="toggleSidebar" class="cursor-pointer p-2 flex items-center justify-center">
                    <i class="i-mdi-menu text-xl"></i>
                </a>
            </div>

            <!-- 侧边栏菜单 -->
            <div class="flex flex-col py-2">
                <a v-for="item in sidebarItems" :key="item.id" :class="[
                    'flex items-center py-2 px-4 cursor-pointer text-neutral-300 overflow-hidden whitespace-nowrap border-l-2',
                    activeTab === item.id ? 'text-white bg-neutral-700 border-l-blue-500' : 'border-l-transparent hover:bg-neutral-700/50'
                ]" @click="activeTab = item.id">
                    <i :class="[item.icon, 'text-xl min-w-6']"></i>
                    <span v-if="sidebarExpanded" class="ml-3">{{ item.name }}</span>
                </a>

                <!-- 插件提供的视图 -->
                <div v-if="pluginViews.length > 0 && sidebarExpanded" class="px-4 pt-4 pb-2">
                    <div class="uppercase text-xs tracking-wider text-neutral-500">插件</div>
                </div>
                <a v-for="view in pluginViews" :key="view.id" :class="[
                    'flex items-center py-2 px-4 cursor-pointer text-neutral-300 overflow-hidden whitespace-nowrap border-l-2',
                    activeTab === view.id ? 'text-white bg-neutral-700 border-l-blue-500' : 'border-l-transparent hover:bg-neutral-700/50'
                ]" @click="activeTab = view.id">
                    <i :class="[view.icon || 'i-mdi-view-dashboard', 'text-xl min-w-6']"></i>
                    <span v-if="sidebarExpanded" class="ml-3">{{ view.name }}</span>
                </a>
            </div>
        </div>

        <!-- 主内容区域 -->
        <div class="flex-1 bg-neutral-900 text-neutral-300 overflow-y-auto">
            <div v-if="activeTab === 'home'" class="p-4 h-full">
                <img alt="logo" class="block mx-auto max-w-[200px]" src="./assets/electron.svg">
                <Versions />
            </div>

            <div v-if="activeTab === 'plugins'" class="p-4 h-full">
                <PluginManager />
            </div>

            <!-- 动态加载插件视图 -->
            <template v-for="view in pluginViews" :key="view.id">
                <div v-if="activeTab === view.id" class="p-4 h-full">
                    <PluginView :component-path="view.absolutePath" />
                </div>
            </template>
        </div>
    </div>
</template>

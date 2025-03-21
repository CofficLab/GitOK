<script setup lang="ts">
import { ref, onMounted, reactive } from 'vue'
import TitleBar from './components/TitleBar.vue'
import PluginManager from './components/PluginManager.vue'
import PluginView from './components/PluginView.vue'
import "./app.css"

const activeTab = ref('home')
const sidebarItems = ref([
    { id: 'home', name: '首页', icon: 'i-mdi-home' },
    { id: 'plugin-manager', name: '插件管理', icon: 'i-mdi-puzzle' }
])
const sidebarExpanded = ref(true)

// 存储插件视图信息
const pluginViews = reactive<any[]>([])

// 切换侧边栏展开/收起状态
const toggleSidebar = () => {
    sidebarExpanded.value = !sidebarExpanded.value
}

// 检查当前是否有已激活的插件视图
const hasActivePluginView = () => {
    return pluginViews.some(view => view.id === activeTab.value)
}

// 加载插件视图
const loadPluginViews = async () => {
    try {
        console.log('📥 正在加载插件视图...')
        const views = await window.api.plugins.getViews()
        console.log('📋 获取到插件视图:', views)

        // 清空当前视图列表
        pluginViews.length = 0

        // 添加新的插件视图
        if (views && views.length > 0) {
            views.forEach(view => {
                pluginViews.push(view)

                // 将视图添加到侧边栏
                if (!sidebarItems.value.some(item => item.id === view.id)) {
                    sidebarItems.value.push({
                        id: view.id,
                        name: view.name,
                        icon: view.icon || 'i-mdi-view-dashboard'
                    })
                }
            })
            console.log('✅ 插件视图加载成功，数量:', pluginViews.length)
        }
    } catch (error) {
        console.error('❌ 加载插件视图失败:', error)
    }
}

// 监听插件安装事件，重新加载插件视图
const setupPluginListeners = () => {
    if (window.api.plugins.onPluginInstalled) {
        window.api.plugins.onPluginInstalled(() => {
            console.log('🔄 检测到插件安装，重新加载视图')
            loadPluginViews()
        })
    }
}

onMounted(() => {
    loadPluginViews()
    setupPluginListeners()
})
</script>

<template>
    <div class="app-container h-screen flex flex-col bg-base-100 text-base-content">
        <TitleBar />

        <div class="main-container flex flex-1 overflow-hidden">
            <!-- 侧边栏 -->
            <div class="sidebar bg-base-200 h-full transition-all duration-300 border-r border-base-300 flex flex-col"
                :class="{ 'w-64': sidebarExpanded, 'w-16': !sidebarExpanded }">
                <div class="sidebar-header flex items-center p-2 border-b border-base-300">
                    <button class="btn btn-sm btn-circle btn-ghost" @click="toggleSidebar"
                        :title="sidebarExpanded ? '收起侧边栏' : '展开侧边栏'">
                        <i :class="sidebarExpanded ? 'i-mdi-chevron-left' : 'i-mdi-chevron-right'" class="text-xl"></i>
                    </button>
                    <h2 class="ml-2 font-bold truncate" v-if="sidebarExpanded">GitOK</h2>
                </div>

                <div class="sidebar-content flex-1 overflow-y-auto">
                    <ul class="menu p-2">
                        <li v-for="item in sidebarItems" :key="item.id">
                            <a :class="{ 'active': activeTab === item.id }" @click="activeTab = item.id"
                                class="flex items-center p-2 rounded-md">
                                <i :class="item.icon" class="text-xl"></i>
                                <span v-if="sidebarExpanded" class="ml-2 truncate">{{ item.name }}</span>
                            </a>
                        </li>
                    </ul>
                </div>
            </div>

            <!-- 主内容区域 -->
            <div class="content-area flex-1 overflow-auto p-6">
                <!-- 首页 -->
                <div v-if="activeTab === 'home'" class="home-view">
                    <h1 class="text-2xl font-bold mb-6">欢迎使用 GitOK</h1>
                </div>

                <!-- 插件管理 -->
                <PluginManager v-else-if="activeTab === 'plugin-manager'" />

                <!-- 插件视图 -->
                <template v-else>
                    <PluginView v-for="view in pluginViews" :key="view.id" v-show="activeTab === view.id" :id="view.id"
                        :name="view.name" :absolutePath="view.absolutePath" :icon="view.icon" />
                    <div v-if="!hasActivePluginView()" class="text-center py-10">
                        <p class="text-xl text-gray-500">未找到相关视图</p>
                    </div>
                </template>
            </div>
        </div>
    </div>
</template>

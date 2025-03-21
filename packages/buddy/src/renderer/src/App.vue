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
    <div class="app-container">
        <!-- 左侧侧边栏 -->
        <div class="sidebar" :class="{ 'sidebar-collapsed': !sidebarExpanded }">
            <!-- 侧边栏顶部图标 -->
            <div class="sidebar-header">
                <a @click="toggleSidebar" class="sidebar-toggle-btn">
                    <i class="i-mdi-menu text-xl"></i>
                </a>
            </div>

            <!-- 侧边栏菜单 -->
            <div class="sidebar-menu">
                <a v-for="item in sidebarItems" :key="item.id" class="sidebar-item"
                    :class="{ 'active': activeTab === item.id }" @click="activeTab = item.id">
                    <i :class="[item.icon, 'sidebar-item-icon']"></i>
                    <span v-if="sidebarExpanded" class="sidebar-item-text">{{ item.name }}</span>
                </a>

                <!-- 插件提供的视图 -->
                <div class="sidebar-section" v-if="pluginViews.length > 0 && sidebarExpanded">
                    <div class="sidebar-section-title">插件</div>
                </div>
                <a v-for="view in pluginViews" :key="view.id" class="sidebar-item"
                    :class="{ 'active': activeTab === view.id }" @click="activeTab = view.id">
                    <i :class="[view.icon || 'i-mdi-view-dashboard', 'sidebar-item-icon']"></i>
                    <span v-if="sidebarExpanded" class="sidebar-item-text">{{ view.name }}</span>
                </a>
            </div>
        </div>

        <!-- 主内容区域 -->
        <div class="main-content">
            <div v-if="activeTab === 'home'" class="content-view">
                <img alt="logo" class="logo" src="./assets/electron.svg">
                <Versions />
            </div>

            <div v-if="activeTab === 'plugins'" class="content-view">
                <PluginManager />
            </div>

            <!-- 动态加载插件视图 -->
            <template v-for="view in pluginViews" :key="view.id">
                <div v-if="activeTab === view.id" class="content-view">
                    <PluginView :component-path="view.absolutePath" />
                </div>
            </template>
        </div>
    </div>
</template>

<style>
.app-container {
    margin-top: 38px;
    /* 为标题栏留出空间 */
    height: calc(100vh - 38px);
    display: flex;
    overflow: hidden;
}

/* 侧边栏样式 */
.sidebar {
    width: 240px;
    background-color: #252526;
    color: #cccccc;
    transition: width 0.2s;
    display: flex;
    flex-direction: column;
    overflow-y: auto;
}

.sidebar-collapsed {
    width: 48px;
}

.sidebar-header {
    height: 48px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-bottom: 1px solid #3c3c3c;
}

.sidebar-toggle-btn {
    cursor: pointer;
    padding: 8px;
    display: flex;
    align-items: center;
    justify-content: center;
}

.sidebar-menu {
    display: flex;
    flex-direction: column;
    padding: 8px 0;
}

.sidebar-item {
    display: flex;
    align-items: center;
    padding: 8px 16px;
    cursor: pointer;
    color: #cccccc;
    border-left: 2px solid transparent;
    overflow: hidden;
    white-space: nowrap;
}

.sidebar-item:hover {
    background-color: #2a2d2e;
}

.sidebar-item.active {
    color: #ffffff;
    background-color: #37373d;
    border-left-color: #007fd4;
}

.sidebar-item-icon {
    font-size: 1.25rem;
    min-width: 24px;
}

.sidebar-item-text {
    margin-left: 12px;
}

.sidebar-section {
    padding: 16px 16px 8px;
}

.sidebar-section-title {
    text-transform: uppercase;
    font-size: 0.8rem;
    letter-spacing: 1px;
    color: #6e6e6e;
}

/* 主内容区域样式 */
.main-content {
    flex: 1;
    background-color: #1e1e1e;
    color: #cccccc;
    overflow-y: auto;
}

.content-view {
    padding: 16px;
    height: 100%;
}

.logo {
    display: block;
    margin: 0 auto;
    max-width: 200px;
}
</style>

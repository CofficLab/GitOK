<script setup lang="ts">
import { ref, onMounted, reactive } from 'vue'
import Versions from "./components/Versions.vue"
import TitleBar from "./components/TitleBar.vue"
import PluginView from './components/plugins/PluginView.vue'
import { BuddyPluginViewInfo } from './types/plugins'
import "./app.css"

// 活动标签页
const activeTab = ref('home')

// 插件视图
const pluginViews = reactive<BuddyPluginViewInfo[]>([])

// 加载插件视图
onMounted(async () => {
  try {
    const views = await window.api.plugins.getViews()
    pluginViews.push(...views)
  } catch (error) {
    console.error('加载插件视图失败:', error)
  }
})
</script>

<template>
  <TitleBar />
  <div class="container flex flex-col h-screen">
    <!-- 标签页内容 -->
    <div class="flex-1 overflow-auto p-4">
      <div v-if="activeTab === 'home'" class="h-full">
        <img alt="logo" class="logo" src="./assets/electron.svg" />
        <Versions />
      </div>

      <!-- 动态加载插件视图 -->
      <template v-for="view in pluginViews" :key="view.id">
        <div v-if="activeTab === view.id" class="h-full">
          <PluginView :component-path="view.absolutePath" />
        </div>
      </template>
    </div>

    <!-- 底部标签页导航 -->
    <div class="tabs tabs-boxed bg-base-200 p-2">
      <a class="tab" :class="{ 'tab-active': activeTab === 'home' }" @click="activeTab = 'home'">
        首页
      </a>
      <!-- 动态生成插件标签页 -->
      <a v-for="view in pluginViews" :key="view.id" class="tab" :class="{ 'tab-active': activeTab === view.id }"
        @click="activeTab = view.id">
        <span v-if="view.icon" class="mr-1">
          <i :class="view.icon"></i>
        </span>
        {{ view.name }}
      </a>
    </div>
  </div>
</template>

<style>
.container {
  margin-top: 38px;
  /* 为标题栏留出空间 */
  padding-bottom: 0;
}
</style>

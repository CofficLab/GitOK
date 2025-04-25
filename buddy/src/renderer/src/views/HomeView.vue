/**
* 首页视图组件
*
* 功能：
* 1. 显示欢迎信息
* 2. 提供初始导航指引
* 3. 显示插件视图网格
*/
<script setup lang="ts">
import { useActionStore } from '@renderer/stores/actionStore';
import ActionListView from './ActionListView.vue';
import PluginView from './PluginView.vue';
import PluginPageGrid from './PluginPageGrid.vue';

const actionStore = useActionStore();

// 处理返回到动作列表
const handleBackToList = () => {
    actionStore.clearSelected();
};
</script>

<template>
    <div class="w-full flex flex-col">
        <!-- 显示HomeView内容（当没有搜索关键词且没有插件动作时） -->
        <div v-if="!actionStore.hasWillRun() && actionStore.getActionCount() === 0" class="p-4">
            <h2 class="text-2xl font-bold mb-4">欢迎使用</h2>
            <p class="text-base-content/70">
                开始输入以搜索可用的动作...
            </p>
        </div>

        <!-- 插件动作列表（当有搜索关键词或有插件动作时） -->
        <div v-if="!actionStore.hasWillRun() && actionStore.getActionCount() > 0" class="flex-1 w-full px-1">
            <ActionListView />

            <!-- 插件视图网格 -->
            <div class="min-h-96 w-full z-30" v-if="false">
                <PluginPageGrid />
            </div>
        </div>

        <!-- 插件动作视图 -->
        <div v-if="actionStore.hasWillRun()" class="flex-1 overflow-auto">
            <PluginView @back="handleBackToList" class="w-full" />
        </div>
    </div>
</template>

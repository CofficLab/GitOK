/**
* 首页视图组件
*
* 功能：
* 1. 显示欢迎信息
* 2. 提供初始导航指引
*/
<script setup lang="ts">
import { useActionStore } from '@renderer/stores/actionStore';
import { computed } from 'vue';

const actionStore = useActionStore();

const hasActions = computed(() => actionStore.getActionCount() > 0);
</script>

<template>
    <div class="flex flex-col justify-center items-center p-4" v-if="hasActions == false">
        <h1 class="text-2xl font-bold mb-4">欢迎使用 Buddy</h1>
        <p class="text-gray-500 text-sm">在搜索框中输入关键词来查找可用的动作</p>
    </div>
</template>
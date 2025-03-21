<template>
    <div class="plugin-view h-full">
        <component v-if="componentLoaded" :is="dynamicComponent"></component>
        <div v-else-if="error" class="error-container">
            <div class="alert alert-error">
                <span>插件加载失败: {{ error }}</span>
            </div>
        </div>
        <div v-else class="loading-container flex justify-center items-center h-full">
            <div class="loading loading-spinner loading-lg"></div>
        </div>
    </div>
</template>

<script lang="ts" setup>
import { ref, onMounted, defineProps, watch } from 'vue';

const props = defineProps<{
    componentPath: string;
}>();

const dynamicComponent = ref<any>(null);
const componentLoaded = ref(false);
const error = ref<string | null>(null);

// 加载组件的方法
const loadComponent = async () => {
    if (!props.componentPath) {
        error.value = '未提供组件路径';
        return;
    }

    try {
        // 重置状态
        componentLoaded.value = false;
        error.value = null;

        console.log(`尝试加载插件视图组件: ${props.componentPath}`);

        // 动态导入组件
        const component = await import(/* @vite-ignore */ props.componentPath);
        dynamicComponent.value = component.default;
        componentLoaded.value = true;

        console.log('插件视图组件加载成功');
    } catch (err) {
        console.error('加载插件视图失败:', err);
        error.value = err instanceof Error ? err.message : '未知错误';
    }
};

// 监听组件路径变化
watch(() => props.componentPath, (newPath) => {
    if (newPath) {
        loadComponent();
    }
});

// 组件挂载时加载
onMounted(() => {
    loadComponent();
});
</script>

<style scoped>
.error-container {
    padding: 1rem;
    height: 100%;
    display: flex;
    flex-direction: column;
    justify-content: center;
}
</style>
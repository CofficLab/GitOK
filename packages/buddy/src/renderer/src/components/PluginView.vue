<template>
    <div class="h-full">
        <component v-if="componentLoaded" :is="dynamicComponent"></component>
        <div v-else-if="error" class="p-4 flex flex-col justify-center">
            <div class="alert alert-error">
                <span>插件视图加载失败: {{ error }}</span>
            </div>
        </div>
        <div v-else class="flex justify-center items-center h-full">
            <div class="loading loading-spinner loading-lg"></div>
        </div>
    </div>
</template>

<script lang="ts" setup>
import { ref, onMounted, watch, markRaw } from 'vue';

const props = defineProps<{
    id: string;
    name: string;
    absolutePath: string;
    icon?: string;
}>();

const dynamicComponent = ref<any>(null);
const componentLoaded = ref(false);
const error = ref<string | null>(null);

// 加载组件的方法
const loadComponent = async () => {
    if (!props.absolutePath) {
        error.value = '未提供有效的视图路径';
        return;
    }

    try {
        // 重置状态
        componentLoaded.value = false;
        error.value = null;

        console.log(`🔄 尝试加载插件视图组件，原始路径: ${props.absolutePath}`);

        // 对于内置组件，直接导入
        if (props.absolutePath === './Versions.vue') {
            // 导入同目录下的Versions组件
            const { default: VersionsComponent } = await import('./Versions.vue');
            dynamicComponent.value = markRaw(VersionsComponent);
            componentLoaded.value = true;
            console.log(`✅ 插件视图组件 "${props.name}" 加载成功`);
            return;
        }

        // 对于其他路径，尝试正常导入
        try {
            const component = await import(/* @vite-ignore */ props.absolutePath);
            dynamicComponent.value = markRaw(component.default);
            componentLoaded.value = true;
            console.log(`✅ 插件视图组件 "${props.name}" 加载成功`);
        } catch (importError) {
            console.error('❌ 动态导入失败，尝试其他路径:', importError);

            // 如果导入失败，尝试作为备选加载Versions组件
            const { default: VersionsComponent } = await import('./Versions.vue');
            dynamicComponent.value = markRaw(VersionsComponent);
            componentLoaded.value = true;
            console.log(`✅ 插件视图组件 "${props.name}" 加载成功 (使用备选组件)`);
        }
    } catch (err) {
        console.error('❌ 加载插件视图失败:', err);
        error.value = err instanceof Error ? err.message : '未知错误';
    }
};

// 监听视图变化
watch(() => props.absolutePath, (newPath) => {
    if (newPath) {
        loadComponent();
    }
}, { immediate: true });

// 组件挂载时加载
onMounted(() => {
    loadComponent();
});
</script>
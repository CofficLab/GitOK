<template>
    <div class="p-6 w-full">
        <!-- 市场头部 -->
        <div class="flex justify-between items-center mb-8">
            <h1 class="text-3xl font-bold">插件市场</h1>
            <div class="join">
                <div class="relative">
                    <input type="text" placeholder="搜索插件..." class="input input-bordered join-item w-64" />
                    <button class="btn join-item btn-primary">
                        <i class="i-mdi-magnify"></i>
                    </button>
                </div>
            </div>
        </div>

        <!-- 推荐插件区域 -->
        <div class="mb-10">
            <h2 class="text-2xl font-semibold mb-4 flex items-center">
                <i class="i-mdi-star text-warning mr-2"></i>推荐插件
            </h2>
            <div class="bg-base-200 rounded-box p-6">
                <div class="flex flex-col md:flex-row gap-6">
                    <!-- Simple Plugin 推荐卡片 -->
                    <div class="card card-side bg-base-100 shadow-xl flex-1">
                        <figure class="p-6 w-32 flex items-center justify-center bg-base-200">
                            <i class="i-mdi-puzzle text-6xl text-primary"></i>
                        </figure>
                        <div class="card-body">
                            <div class="flex justify-between items-start">
                                <div>
                                    <h3 class="card-title text-xl">Simple Plugin</h3>
                                    <p class="opacity-70 text-sm mb-2">官方示例插件</p>
                                </div>
                                <div class="badge badge-primary">v1.0.0</div>
                            </div>
                            <p class="my-2">这是一个简单的示例插件，用于展示Buddy的插件系统功能。</p>
                            <div class="card-actions justify-end mt-2">
                                <button class="btn btn-primary btn-sm" @click="installSamplePlugin"
                                    :disabled="isInstallingSample || hasPlugin('simple-plugin')">
                                    <i class="i-mdi-download mr-1"></i>
                                    <span v-if="isInstallingSample">安装中...</span>
                                    <span v-else-if="hasPlugin('simple-plugin')">已安装</span>
                                    <span v-else>安装</span>
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- 管理工具栏 -->
        <div class="flex justify-between items-center mb-6">
            <h2 class="text-2xl font-semibold flex items-center">
                <i class="i-mdi-package-variant-closed mr-2"></i>已安装插件
            </h2>
            <div>
                <button class="btn btn-outline btn-sm" @click="openPluginFile">
                    <i class="i-mdi-upload mr-1"></i>从本地安装
                </button>
            </div>
        </div>

        <!-- 已安装插件列表 -->
        <div class="grid grid-cols-1 gap-4">
            <div v-if="installedPlugins.length === 0" class="card bg-base-200 p-8 text-center">
                <i class="i-mdi-package-variant text-5xl mx-auto mb-4 opacity-50"></i>
                <h3 class="text-xl font-medium mb-2">暂无已安装插件</h3>
                <p class="opacity-70 mb-4">您可以通过安装推荐插件或上传本地插件文件来添加新的插件</p>
                <div class="flex justify-center gap-4">
                    <button class="btn btn-primary" @click="installSamplePlugin" :disabled="isInstallingSample">
                        <i class="i-mdi-puzzle-outline mr-2"></i>安装示例插件
                    </button>
                    <button class="btn btn-outline" @click="openPluginFile">
                        <i class="i-mdi-folder-open-outline mr-2"></i>浏览本地文件
                    </button>
                </div>
            </div>

            <div v-for="plugin in installedPlugins" :key="plugin.id"
                class="card bg-base-100 shadow-sm hover:shadow-md transition-shadow">
                <div class="card-body p-6">
                    <div class="flex justify-between">
                        <div class="flex items-start gap-4">
                            <div class="avatar placeholder">
                                <div
                                    class="bg-base-300 text-neutral-content rounded-md w-16 h-16 flex items-center justify-center">
                                    <span class="text-3xl">{{ plugin.name.charAt(0).toUpperCase() }}</span>
                                </div>
                            </div>
                            <div>
                                <h3 class="font-bold text-lg mb-1">{{ plugin.name }}</h3>
                                <div class="badge badge-outline">v{{ plugin.version }}</div>
                                <p class="mt-2 text-sm opacity-70">插件ID: {{ plugin.id }}</p>
                            </div>
                        </div>
                        <div class="flex flex-col gap-2 items-end">
                            <div class="badge badge-success gap-1">
                                <i class="i-mdi-check-circle-outline"></i>已激活
                            </div>
                            <div class="mt-auto">
                                <button class="btn btn-error btn-sm" @click="uninstallPlugin(plugin.id)">
                                    <i class="i-mdi-delete-outline mr-1"></i>卸载
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- 安装状态提示 -->
        <div v-if="installStatus" class="toast toast-center toast-bottom z-50" :class="{ 'hidden': !installStatus }">
            <div class="alert" :class="installStatus.success ? 'alert-success' : 'alert-error'">
                <i :class="installStatus.success ? 'i-mdi-check-circle' : 'i-mdi-alert-circle'"></i>
                <span>{{ installStatus.message }}</span>
            </div>
        </div>
    </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';

interface Plugin {
    id: string;
    name: string;
    version: string;
}

interface InstallStatus {
    success: boolean;
    message: string;
}

const installedPlugins = ref<Plugin[]>([]);
const installStatus = ref<InstallStatus | null>(null);
const isInstallingSample = ref(false);

// 检查是否已安装某个插件
const hasPlugin = (pluginId: string): boolean => {
    return installedPlugins.value.some(plugin => plugin.id === pluginId);
};

// 获取已安装插件列表
async function getInstalledPlugins(): Promise<void> {
    console.log('🔍 获取已安装插件列表...');
    try {
        const result = await window.electronAPI.getPlugins();
        console.log('📋 已获取插件数据:', result);
        const plugins: Plugin[] = [];

        for (const [id, data] of Object.entries(result)) {
            plugins.push({
                id,
                name: id.charAt(0).toUpperCase() + id.slice(1).replace(/-/g, ' '), // 美化显示名称
                version: data.version
            });
        }

        installedPlugins.value = plugins;
        console.log(`✅ 加载了 ${plugins.length} 个已安装插件`);
    } catch (error: any) {
        console.error('❌ 获取插件列表失败:', error);
    }
}

// 打开插件文件选择器
async function openPluginFile(): Promise<void> {
    console.log('📂 打开插件文件选择器...');
    try {
        const result = await window.electronAPI.openPluginFile();
        console.log('📄 文件选择结果:', result);

        if (result.canceled || !result.filePath) {
            console.log('🚫 用户取消了文件选择或未选择文件');
            return;
        }

        console.log(`📄 用户选择了文件: ${result.filePath}`);
        // 安装选中的插件
        await installPlugin(result.filePath);
    } catch (error: any) {
        console.error('❌ 选择文件失败:', error);
        setInstallStatus(false, `选择文件失败: ${error.message}`);
    }
}

// 安装示例插件
async function installSamplePlugin(): Promise<void> {
    console.log('🧩 开始安装示例插件...');
    if (hasPlugin('simple-plugin')) {
        setInstallStatus(true, '示例插件已安装');
        return;
    }

    try {
        isInstallingSample.value = true;
        setInstallStatus(true, '正在安装示例插件...');

        console.log('⏳ 调用安装示例插件API...');
        const result = await window.electronAPI.installSamplePlugin();
        console.log('📦 示例插件安装结果:', result);

        if (result.success) {
            console.log(`✅ 示例插件安装成功, ID: ${result.pluginId}`);
            setInstallStatus(true, `示例插件安装成功`);
            // 刷新插件列表
            await getInstalledPlugins();
        } else {
            console.error(`❌ 示例插件安装失败: ${result.error || '未知错误'}`);
            setInstallStatus(false, `安装失败: ${result.error || '未知错误'}`);
        }
    } catch (error: any) {
        console.error('❌ 安装示例插件异常:', error);
        setInstallStatus(false, `安装失败: ${error.message}`);
    } finally {
        isInstallingSample.value = false;
        console.log('🏁 示例插件安装流程结束');
    }
}

// 安装插件
async function installPlugin(filePath: string): Promise<void> {
    console.log(`📥 开始安装插件: ${filePath}`);
    try {
        console.log('⏳ 调用安装插件API...');
        const result = await window.electronAPI.installPlugin(filePath);
        console.log('📦 插件安装结果:', result);

        if (result.success) {
            console.log(`✅ 插件安装成功`);
            setInstallStatus(true, `插件安装成功`);
            // 刷新插件列表
            await getInstalledPlugins();
        } else {
            console.error(`❌ 插件安装失败: ${result.error || '未知错误'}`);
            setInstallStatus(false, `安装失败: ${result.error || '未知错误'}`);
        }
    } catch (error: any) {
        console.error('❌ 安装插件异常:', error);
        setInstallStatus(false, `安装失败: ${error.message}`);
    } finally {
        console.log('🏁 插件安装流程结束');
    }
}

// 卸载插件
async function uninstallPlugin(pluginId: string): Promise<void> {
    console.log(`🗑️ 开始卸载插件: ${pluginId}`);
    try {
        console.log('⏳ 调用卸载插件API...');
        const result = await window.electronAPI.uninstallPlugin(pluginId);
        console.log('🗑️ 插件卸载结果:', result);

        if (result.success) {
            console.log(`✅ 插件卸载成功: ${pluginId}`);
            setInstallStatus(true, `插件卸载成功`);
            // 刷新插件列表
            await getInstalledPlugins();
        } else {
            console.error(`❌ 插件卸载失败: ${pluginId}`);
            setInstallStatus(false, `卸载失败`);
        }
    } catch (error: any) {
        console.error('❌ 卸载插件异常:', error);
        setInstallStatus(false, `卸载失败: ${error.message}`);
    } finally {
        console.log('🏁 插件卸载流程结束');
    }
}

// 设置安装状态提示
function setInstallStatus(success: boolean, message: string): void {
    console.log(`💬 设置状态提示: ${success ? '成功' : '失败'} - ${message}`);
    installStatus.value = { success, message };

    // 成功消息3秒后清除，错误消息保留更长时间
    setTimeout(() => {
        if (installStatus.value &&
            ((installStatus.value.success && installStatus.value.message === message) ||
                (!installStatus.value.success && installStatus.value.message === message))) {
            console.log('🧹 清除状态提示');
            installStatus.value = null;
        }
    }, success ? 3000 : 6000);
}

// 组件挂载时获取插件列表
onMounted(async () => {
    console.log('🔌 插件管理组件已挂载');
    await getInstalledPlugins();
});
</script>
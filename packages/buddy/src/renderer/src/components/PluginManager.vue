<template>
    <div class="p-8 max-w-4xl mx-auto">
        <h2 class="text-2xl font-bold mb-6">插件管理</h2>

        <!-- 安装插件卡片 -->
        <div class="card bg-base-100 shadow-xl mb-6">
            <div class="card-body">
                <h3 class="card-title">安装新插件</h3>
                <p>从本地文件安装Buddy插件</p>
                <div class="card-actions justify-end">
                    <button class="btn btn-primary" @click="openPluginFile">
                        <i class="i-mdi-plus-circle mr-2"></i> 安装插件
                    </button>
                </div>
            </div>
        </div>

        <!-- 安装示例插件卡片 -->
        <div class="card bg-base-100 shadow-xl mb-6">
            <div class="card-body">
                <h3 class="card-title">安装示例插件</h3>
                <p>安装项目中提供的简单示例插件</p>
                <div class="card-actions justify-end">
                    <button class="btn btn-secondary" @click="installSamplePlugin" :disabled="isInstallingSample">
                        <i class="i-mdi-puzzle-outline mr-2"></i>
                        {{ isInstallingSample ? '安装中...' : '安装示例插件' }}
                    </button>
                </div>
            </div>
        </div>

        <!-- 已安装插件列表 -->
        <div v-if="installedPlugins.length > 0">
            <h3 class="text-xl font-semibold mb-4">已安装插件</h3>
            <div class="grid gap-4">
                <div v-for="plugin in installedPlugins" :key="plugin.id"
                    class="card card-compact bg-base-100 shadow-sm">
                    <div class="card-body">
                        <div class="flex justify-between items-center">
                            <div>
                                <h4 class="card-title">{{ plugin.name }}</h4>
                                <p class="text-sm opacity-70">版本: {{ plugin.version }}</p>
                            </div>
                            <div class="flex gap-2">
                                <button class="btn btn-sm btn-error" @click="uninstallPlugin(plugin.id)">
                                    卸载
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div v-else class="alert alert-info">
            <i class="i-mdi-information-outline"></i>
            <span>尚未安装任何插件</span>
        </div>

        <!-- 安装状态提示 -->
        <div v-if="installStatus" :class="['alert mt-4', installStatus.success ? 'alert-success' : 'alert-error']">
            <i :class="installStatus.success ? 'i-mdi-check-circle' : 'i-mdi-alert-circle'"></i>
            <span>{{ installStatus.message }}</span>
        </div>
    </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';

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
                name: id, // 实际应用中应该从manifest提取
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
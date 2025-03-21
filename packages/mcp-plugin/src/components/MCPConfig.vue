<template>
    <div class="card bg-base-200">
        <div class="card-body p-4">
            <h3 class="card-title text-lg">配置</h3>

            <div class="form-control">
                <label class="label">
                    <span class="label-text">脚本路径</span>
                </label>
                <div class="input-group">
                    <input type="text" class="input input-bordered w-full" placeholder="输入脚本路径" :value="scriptPath"
                        @input="$emit('update:scriptPath', ($event.target as HTMLInputElement).value)"
                        :disabled="isRunning" />
                    <button class="btn btn-square" @click="selectScriptFile" :disabled="isRunning">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24"
                            stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                d="M9 13h6m-3-3v6m5 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                        </svg>
                    </button>
                </div>
            </div>

            <div class="form-control mt-2">
                <label class="label">
                    <span class="label-text">启动命令 (每行一条)</span>
                </label>
                <textarea class="textarea textarea-bordered w-full h-24" placeholder="输入启动命令，每行一条"
                    :value="startupCommandsText"
                    @input="updateStartupCommands(($event.target as HTMLTextAreaElement).value)" :disabled="isRunning">
                </textarea>
            </div>

            <div class="flex justify-between mt-4">
                <div class="flex gap-2">
                    <button class="btn btn-sm" @click="$emit('save-config')" :disabled="isRunning">
                        保存配置
                    </button>
                    <button class="btn btn-sm" @click="$emit('load-config')" :disabled="isRunning">
                        加载配置
                    </button>
                </div>

                <button v-if="!isRunning" class="btn btn-primary btn-sm" @click="$emit('start')"
                    :disabled="!scriptPath">
                    启动服务
                </button>
                <button v-else class="btn btn-error btn-sm" @click="$emit('stop')">
                    停止服务
                </button>
            </div>
        </div>
    </div>
</template>

<script lang="ts" setup>
import { computed } from 'vue';

const props = defineProps<{
    scriptPath: string
    startupCommands: string[]
    isRunning: boolean
}>();

// 定义emit函数
const emit = defineEmits<{
    (e: 'update:scriptPath', value: string): void
    (e: 'update:startupCommands', value: string[]): void
    (e: 'start'): void
    (e: 'stop'): void
    (e: 'save-config'): void
    (e: 'load-config'): void
}>();

// 转换命令数组为文本
const startupCommandsText = computed(() => props.startupCommands.join('\n'));

// 更新启动命令
const updateStartupCommands = (text: string): void => {
    const commands = text
        .split('\n')
        .map(cmd => cmd.trim())
        .filter(cmd => cmd !== '');

    emit('update:startupCommands', commands);
};

// 文件选择对话框
const selectScriptFile = async (): Promise<void> => {
    try {
        // 使用Browser API打开文件选择对话框
        const input = document.createElement('input');
        input.type = 'file';
        input.accept = '.js,.ts,.txt';

        input.onchange = (event) => {
            const files = (event.target as HTMLInputElement).files;
            if (files && files.length > 0) {
                emit('update:scriptPath', files[0].path);
            }
        };

        input.click();
    } catch (error) {
        console.error('选择文件失败:', error);
    }
};
</script>
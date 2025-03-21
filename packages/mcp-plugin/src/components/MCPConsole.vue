<template>
    <div class="card bg-base-300 flex-1 max-h-[400px] overflow-hidden flex flex-col">
        <div class="card-body p-4 flex flex-col gap-1 flex-1 overflow-hidden">
            <div class="flex justify-between items-center">
                <h3 class="card-title text-lg">控制台输出</h3>
                <button class="btn btn-xs btn-ghost" @click="$emit('clear')" title="清除控制台">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24"
                        stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                            d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                    </svg>
                </button>
            </div>

            <div ref="logContainer" class="font-mono text-sm overflow-y-auto flex-1 rounded bg-base-100 p-3">
                <template v-if="logs.length === 0">
                    <div class="text-base-content/50 text-center py-4">
                        控制台输出将显示在这里
                    </div>
                </template>

                <div v-for="(log, index) in logs" :key="index" class="mb-1 break-all" :class="{
                    'text-info': log.type === 'info',
                    'text-error': log.type === 'error',
                    'text-warning font-bold': log.type === 'command',
                    'text-success': log.type === 'system'
                }">
                    {{ log.text }}
                </div>
            </div>
        </div>
    </div>
</template>

<script lang="ts" setup>
import { ref, defineProps, defineEmits, defineExpose } from 'vue'

defineProps<{
    logs: {
        text: string
        type: 'info' | 'error' | 'command' | 'system'
    }[]
}>();

defineEmits<{
    (e: 'clear'): void
}>();

const logContainer = ref<HTMLElement | null>(null);

// 滚动到底部的方法
const scrollToBottom = (): void => {
    if (logContainer.value) {
        logContainer.value.scrollTop = logContainer.value.scrollHeight;
    }
};

// 暴露方法给父组件使用
defineExpose({
    scrollToBottom
});
</script>
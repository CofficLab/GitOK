<template>
    <div class="card bg-base-200">
        <div class="card-body p-4">
            <div class="flex justify-between items-center">
                <h3 class="card-title text-lg">命令输入</h3>
                <div>
                    <button class="btn btn-ghost btn-xs" @click="showHistory = !showHistory" title="历史命令">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24"
                            stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                    </button>
                </div>
            </div>

            <div class="relative">
                <div v-if="showHistory && historyItems.length > 0"
                    class="absolute bottom-full left-0 right-0 mb-1 bg-base-100 shadow-lg rounded-lg z-10 max-h-32 overflow-y-auto">
                    <ul class="menu menu-compact p-1">
                        <li v-for="(cmd, index) in historyItems" :key="index">
                            <a @click="loadCommand(cmd)" class="text-sm py-1">{{ cmd }}</a>
                        </li>
                    </ul>
                </div>

                <div class="input-group">
                    <input type="text" class="input input-bordered w-full" placeholder="输入命令..." :value="command"
                        @input="$emit('update:command', ($event.target as HTMLInputElement).value)"
                        @keyup.enter="$emit('send')" :disabled="!isRunning" />
                    <button class="btn btn-primary" @click="$emit('send')" :disabled="!isRunning || !command">
                        发送
                    </button>
                </div>
            </div>
        </div>
    </div>
</template>

<script lang="ts" setup>
import { ref, computed } from 'vue'

const props = defineProps<{
    command: string;
    isRunning: boolean;
    commandHistory?: string[];
}>();

const emit = defineEmits<{
    (e: 'update:command', value: string): void;
    (e: 'send'): void;
    (e: 'load-history', command: string): void;
}>();

const showHistory = ref(false);

// 确保commandHistory是数组
const historyItems = computed(() => props.commandHistory || []);

// 加载历史命令
const loadCommand = (command: string): void => {
    showHistory.value = false;
    emit('load-history', command);
};
</script>
<script setup lang="ts">
defineProps<{
    gitRepo: string
    branch: string
    commits: number
    lastUpdated: string
}>()
</script>

<template>
    <div
        class="status-bar flex justify-between items-center px-2 py-1 bg-neutral text-neutral-content text-xs rounded-lg">
        <div class="flex items-center space-x-3">
            <div class="git-info flex items-center">
                <i class="i-mdi-git mr-1"></i>
                <span>{{ gitRepo }}</span>
                <span class="mx-1">/</span>
                <span class="branch">{{ branch }}</span>
            </div>

            <div class="commits">
                <i class="i-mdi-source-commit mr-1"></i>
                <span>{{ commits }} commits</span>
            </div>

            <div class="time">
                <i class="i-mdi-clock-outline mr-1"></i>
                <span>{{ lastUpdated }}</span>
            </div>
        </div>

        <!-- 右侧插槽，可以放置按钮等 -->
        <div class="flex items-center">
            <slot name="right"></slot>
        </div>
    </div>
</template>

<style scoped>
.status-bar {
    min-height: 26px;
}
</style>
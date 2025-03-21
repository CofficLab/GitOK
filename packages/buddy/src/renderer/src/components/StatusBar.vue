<script setup lang="ts">
defineProps<{
    gitRepo: string
    branch: string
    commits: number
    lastUpdated: string
}>()
</script>

<template>
    <div class="status-bar bg-base-200 p-2 rounded-lg flex justify-between items-center text-sm">
        <div class="flex items-center">
            <i class="i-mdi-source-repository mr-1"></i>
            <span>{{ gitRepo }}</span>
            <span class="mx-2">|</span>
            <i class="i-mdi-source-branch mr-1"></i>
            <span>{{ branch }}</span>
        </div>
        <div class="flex items-center">
            <i class="i-mdi-source-commit mr-1"></i>
            <span>{{ commits }} 次提交</span>
            <span class="mx-2">|</span>
            <i class="i-mdi-clock-outline mr-1"></i>
            <span>更新于 {{ lastUpdated }}</span>
        </div>
    </div>
</template>
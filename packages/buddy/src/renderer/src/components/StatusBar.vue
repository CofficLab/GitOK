<script setup lang="ts">
import { useGitStatusStore } from '../stores/gitStatus'

// 使用store
const gitStatus = useGitStatusStore()
</script>

<template>
    <div class="h-12 bg-base-300 p-2 flex justify-between items-center text-sm">
        <div class="flex items-center space-x-4">
            <span class="flex items-center">
                <i class="i-mdi-source-repository mr-1"></i>
                {{ gitStatus.gitRepo }}
            </span>
            <span class="flex items-center">
                <i class="i-mdi-source-branch mr-1"></i>
                {{ gitStatus.branch }}
            </span>
            <span class="flex items-center">
                <i class="i-mdi-source-commit mr-1"></i>
                {{ gitStatus.commits }}
            </span>
            <span class="flex items-center">
                <i class="i-mdi-clock-outline mr-1"></i>
                {{ gitStatus.lastUpdated }}
            </span>
        </div>
    </div>
</template>
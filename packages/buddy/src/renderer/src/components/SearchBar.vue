<script setup lang="ts">
import { useSearchStore } from '../stores/searchStore'

const searchStore = useSearchStore()

// 处理输入
const handleInput = (event: Event) => {
    const target = event.target as HTMLInputElement
    searchStore.updateKeyword(target.value)
}
</script>

<template>
    <div class="search-container">
        <input type="text" :value="searchStore.keyword" @input="handleInput" @keydown="searchStore.handleKeyDown"
            class="input input-bordered w-full" placeholder="搜索Git命令、NPM操作或VS Code功能..." />
    </div>
</template>
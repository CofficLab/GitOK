<script setup lang="ts">
import { ref, defineProps, defineEmits } from 'vue'

defineProps<{
    placeholder?: string
}>()

const searchKeyword = ref('')

const emit = defineEmits<{
    (e: 'search', keyword: string): void
    (e: 'input', keyword: string): void
    (e: 'keydown', event: KeyboardEvent): void
}>()

const handleSearch = () => {
    emit('search', searchKeyword.value)
}

const handleInput = () => {
    emit('input', searchKeyword.value)
}

const handleKeyDown = (event: KeyboardEvent) => {
    emit('keydown', event)
}
</script>

<template>
    <div class="search-container mb-4">
        <div class="relative">
            <input id="search-input" type="text" v-model="searchKeyword" @input="handleInput" @keydown="handleKeyDown"
                :placeholder="placeholder || '搜索...'" class="input input-bordered w-full pl-10 py-3 text-lg"
                autofocus />
            <div class="absolute inset-y-0 left-0 flex items-center pl-3">
                <i class="i-mdi-magnify text-xl text-primary"></i>
            </div>
            <button class="btn btn-primary absolute right-2 top-1/2 transform -translate-y-1/2" @click="handleSearch">
                搜索
            </button>
        </div>
    </div>
</template>
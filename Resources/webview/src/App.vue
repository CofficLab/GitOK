<script setup lang="ts">
import { onMounted } from 'vue';
import MonacoEditor from './components/MonacoEditor.vue'
import { useAppStore } from './store/AppStore';

const appStore = useAppStore();

onMounted(() => {
  window.api = appStore;
})
</script>

<template>
  <MonacoEditor />
</template>

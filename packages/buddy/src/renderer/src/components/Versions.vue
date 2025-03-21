<script setup lang="ts">
import { reactive } from "vue"

const versions = reactive({ ...window.electron.process.versions })
</script>

<template>
  <ul class="list-none p-4 mt-4 text-center">
    <li class="mb-2 text-sm">Electron v{{ versions.electron }}</li>
    <li class="mb-2 text-sm">Chromium v{{ versions.chrome }}</li>
    <li class="mb-2 text-sm">Node v{{ versions.node }}</li>
  </ul>
</template>

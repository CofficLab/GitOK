<script setup lang="ts">
import Versions from "./components/Versions.vue"
import TitleBar from "./components/TitleBar.vue"
import "./app.css"

</script>

<template>
  <TitleBar />
  <div class="container">
    <img alt="logo" class="logo" src="./assets/electron.svg" />

    <Versions />
  </div>
</template>

<style>
.container {
  margin-top: 38px;
  /* 为标题栏留出空间 */
}
</style>

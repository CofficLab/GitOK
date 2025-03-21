<script setup lang="ts">
import Versions from './components/Versions.vue'
import TitleBar from './components/TitleBar.vue'
import './app.css'

const ipcHandle = (): void => window.electron.ipcRenderer.send('ping')
</script>

<template>
  <TitleBar />
  <div class="container">
    <img alt="logo" class="logo" src="./assets/electron.svg" />
    <div class="creator">Powered by electron-vite</div>
    <div class="text">
      Build an Electron app with
      <span class="vue">Vue</span>
      and
      <span class="ts">TypeScript</span>
    </div>
    <h1 class="text-2xl font-bold bg-red-500">Hello World</h1>
    <input type="text" />
    <button class="btn btn-primary">Click me</button>
    <p class="tip">Please try pressing <code>F12</code> to open the devTool</p>
    <div class="actions">
      <div class="action">
        <a href="https://electron-vite.org/" target="_blank" rel="noreferrer">Documentation</a>
      </div>
      <div class="action">
        <a target="_blank" rel="noreferrer" @click="ipcHandle">Send IPC</a>
      </div>
    </div>
    <Versions />
  </div>
</template>

<style>
.container {
  margin-top: 38px;
  /* 为标题栏留出空间 */
}
</style>

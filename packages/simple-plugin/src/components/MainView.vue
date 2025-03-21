<template>
  <div class="simple-plugin-container">
    <div class="card">
      <h1 class="text-2xl font-bold">{{ title }}</h1>
      <p class="my-4">{{ message }}</p>
      <button class="btn btn-primary" @click="handleClick">
        点击我
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';

const title = ref('简单插件');
const message = ref('这是一个Buddy示例插件的视图');

function handleClick() {
  message.value = '按钮被点击了！';
}
</script>

<style scoped>
.simple-plugin-container {
  padding: 2rem;
  display: flex;
  justify-content: center;
  align-items: center;
  height: 100%;
}

.card {
  padding: 2rem;
  background-color: white;
  border-radius: 0.5rem;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  max-width: 500px;
  width: 100%;
}
</style> 
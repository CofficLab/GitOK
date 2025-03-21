<template>
  <div class="p-4">
    <h2 class="text-xl font-bold mb-4">应用版本信息</h2>
    <div class="overflow-x-auto">
      <table class="table table-zebra w-full">
        <thead>
          <tr>
            <th>组件</th>
            <th>版本</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="(version, name) in versions" :key="name">
            <td>{{ name }}</td>
            <td>{{ version }}</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { ref, onMounted } from 'vue';

const versions = ref<Record<string, string>>({
  '应用': '1.0.0',
  'Electron': '未知',
  'Chrome': '未知',
  'Node.js': '未知',
  'V8': '未知'
});

onMounted(async () => {
  try {
    // 简单版本组件，直接显示静态信息
    // 这里仅作为示例插件视图使用
    console.log('Versions组件已加载');
  } catch (error) {
    console.error('加载版本信息失败:', error);
  }
});
</script>

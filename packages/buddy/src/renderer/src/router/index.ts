/**
 * 路由配置
 *
 * 管理应用的所有路由：
 * 1. 使用 hash 模式，适合桌面应用
 * 2. 配置所有可用的视图路由
 * 3. 设置路由元信息，如标题等
 */

import { createRouter, createWebHashHistory } from 'vue-router';
import PluginStoreView from '@renderer/views/PluginStoreView.vue';

// 路由配置
const routes = [
  {
    path: '/',
    name: 'home',
    component: () => import('@renderer/views/HomeView.vue'),
    meta: {
      title: '首页',
    },
  },
  {
    path: '/plugins',
    name: 'plugins',
    component: PluginStoreView,
    meta: {
      title: '插件商店',
    },
  },
];

// 创建路由实例
const router = createRouter({
  history: createWebHashHistory(),
  routes,
});

// 路由守卫：处理窗口标题等
router.beforeEach((to, from, next) => {
  // 设置窗口标题
  if (to.meta.title) {
    document.title = `GitOK - ${to.meta.title}`;
  }
  next();
});

export default router;

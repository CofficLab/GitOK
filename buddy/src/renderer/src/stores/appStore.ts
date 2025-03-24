/**
 * appStore.ts - 应用核心状态管理
 *
 * 这个store负责管理应用的核心状态：
 * 1. 当前视图
 * 2. 插件商店的显示状态
 * 3. 当前选中的动作
 *
 * 主要功能：
 * - 控制视图切换
 * - 控制插件商店的显示/隐藏
 * - 管理当前选中的动作
 *
 * 状态说明：
 * - currentView: 当前显示的视图（home/plugins）
 * - showPluginStore: 控制插件商店的显示状态
 * - selectedAction: 当前选中的插件动作
 *
 * 注意事项：
 * - 切换插件商店时会自动清理选中的动作
 * - 所有视图组件都应该通过这个store来管理状态
 * - 避免直接修改状态，应该使用提供的action
 */

import { defineStore } from 'pinia';
import type { PluginAction } from '@/types/plugin-action';

export type ViewType = 'home' | 'plugins';

interface AppState {
  currentView: ViewType;
  showPluginStore: boolean;
  selectedAction: PluginAction | null;
}

export const useAppStore = defineStore('app', {
  state: (): AppState => ({
    currentView: 'home',
    showPluginStore: false,
    selectedAction: null,
  }),

  actions: {
    setView(view: ViewType) {
      this.currentView = view;
    },

    togglePluginStore() {
      this.showPluginStore = !this.showPluginStore;
      // 如果关闭插件商店，回到主界面
      if (!this.showPluginStore) {
        this.selectedAction = null;
      }
    },

    setSelectedAction(action: PluginAction | null) {
      this.selectedAction = action;
    },
  },
});

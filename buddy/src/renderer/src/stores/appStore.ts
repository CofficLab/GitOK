import { defineStore } from 'pinia';
import { AppEvents, SuperAction, SuperApp } from '@coffic/buddy-types';

const ipc = window.ipc;

export type ViewType = 'home' | 'plugins' | 'chat' | 'plugin-grid';

interface AppState {
  currentView: ViewType;
  showPluginStore: boolean;
  selectedAction: SuperAction | null;
  isActive: boolean; // 添加窗口激活状态
  overlaidApp: SuperApp | null; // 用于记录当前被覆盖的应用
}

export const useAppStore = defineStore('app', {
  state: (): AppState => ({
    currentView: 'home',
    showPluginStore: false,
    selectedAction: null,
    isActive: true, // 默认为激活状态
    overlaidApp: null, // 初始化为null
  }),

  actions: {
    onMounted() {
      this.setupWindowActiveListeners();
      this.setupOverlaidAppListeners();
    },

    onUnmounted() {
      this.cleanupWindowActiveListeners();
    },

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

    setSelectedAction(action: SuperAction | null) {
      this.selectedAction = action;
    },

    // 设置窗口激活状态
    setActiveState(isActive: boolean) {
      this.isActive = isActive;
    },

    setupOverlaidAppListeners() {
      ipc.receive(AppEvents.OVERLAID_APP_CHANGED, (args: any) => {
        this.overlaidApp = args as SuperApp | null;
      });
    },

    // 初始化窗口激活状态监听器
    setupWindowActiveListeners() {
      // 监听窗口激活事件
      ipc.receive(AppEvents.ActIVATED, () => {
        this.setActiveState(true);
      });

      // 监听窗口失活事件
      ipc.receive(AppEvents.DEACTIVATED, () => {
        this.setActiveState(false);
      });
    },

    // 清理窗口激活状态监听器
    cleanupWindowActiveListeners() {
      // 移除监听器
      ipc.removeListener(AppEvents.OVERLAID_APP_CHANGED, () => { });
      ipc.removeListener(AppEvents.ActIVATED, () => { });
      ipc.removeListener(AppEvents.DEACTIVATED, () => { });
    },
  },
});

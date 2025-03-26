import { defineStore } from 'pinia';
import type { SuperAction } from '@/types/super_action';
import { WindowEvents } from '@/types/app-events';
import { logger } from '@renderer/utils/logger';
const electronApi = window.electron;
const { actions: actionsApi } = electronApi.plugins;
const ipc = electronApi.ipc;

/**
 * Action 管理 Store
 *
 * 负责管理动作列表、搜索、执行等功能
 */

interface ActionState {
  list: SuperAction[];
  isLoading: boolean;
  selected: string | null;
  viewHtml: string;
  lastKeyword: string; // 存储上次搜索的关键词，用于窗口激活时刷新
}

export const useActionStore = defineStore('action', {
  state: (): ActionState => ({
    list: [],
    isLoading: false,
    selected: null,
    viewHtml: '',
    lastKeyword: '',
  }),

  actions: {
    /**
     * 加载动作列表
     */
    async loadList(searchKeyword: string = '') {
      logger.info('actionStore: loadList with keyword: 🐛', searchKeyword);
      this.lastKeyword = searchKeyword; // 保存当前关键词

      try {
        this.isLoading = true;
        this.list = await actionsApi.getPluginActions(searchKeyword);

        // logger.info('actionStore: loadList', this.list);
      } catch (error) {
        logger.error('actionStore: loadList error: 🐛', error);
        this.list = [];
        throw error;
      } finally {
        this.isLoading = false;
      }
    },

    /**
     * 执行指定动作
     */
    async execute(actionGlobalId: string): Promise<any> {
      this.selected = actionGlobalId;
      const action = this.find(actionGlobalId);

      if (!action) {
        throw new Error(`未找到动作: ${actionGlobalId}`);
      }

      if (action.viewPath) {
        await this.loadView(action.globalId);
      } else {
        this.viewHtml = '';
      }

      return actionsApi.executeAction(action.globalId);
    },

    /**
     * 加载动作的自定义视图
     */
    async loadView(actionId: string): Promise<void> {
      try {
        this.viewHtml = '';
        const response = await actionsApi.getActionView(actionId);

        if (response.success && response.html) {
          this.viewHtml = response.html;
        } else if (response.error) {
          throw new Error(response.error);
        }
      } catch (error) {
        this.viewHtml = '';
        throw error;
      }
    },

    /**
     * 根据ID获取动作
     */
    find(actionGlobalId: string): SuperAction | undefined {
      return this.list.find((a) => a.globalId === actionGlobalId);
    },

    getSelectedActionId(): string | null {
      return this.selected || null;
    },

    getActionCount(): number {
      return this.list.length;
    },

    /**
     * 清空当前选中的动作
     */
    clearSelected() {
      this.selected = null;
      this.viewHtml = '';
    },

    selectAction(actionId: string) {
      this.selected = actionId;
    },

    getActions(): SuperAction[] {
      return this.list;
    },

    hasSelectedAction(): boolean {
      return this.selected !== null;
    },

    /**
     * 设置窗口激活状态监听
     * 当窗口被激活时，刷新动作列表
     */
    setupWindowActivationListener() {
      ipc.receive(WindowEvents.ACTIVATED, () => {
        // 使用上次的搜索关键词刷新列表
        this.loadList(this.lastKeyword);
      });
    },

    /**
     * 清理窗口激活状态监听
     */
    cleanupWindowActivationListener() {
      ipc.removeListener(WindowEvents.ACTIVATED, () => {});
    },
  },
});

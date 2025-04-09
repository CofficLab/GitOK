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
 *
 * 主要功能：
 * - 管理搜索关键词
 * - 处理搜索结果的更新
 * - 提供搜索状态的响应式访问
 * - 管理动作列表及其状态
 * - 执行指定动作
 * - 加载动作自定义视图
 * - 监听窗口激活状态
 */

interface ActionState {
  list: SuperAction[];
  isLoading: boolean;
  selected: string | null;
  viewHtml: string;
  lastKeyword: string; // 存储上次搜索的关键词，用于窗口激活时刷新
  keyword: string; // 当前搜索关键词
  lastSearchTime: number; // 记录最后一次搜索时间
}

export const useActionStore = defineStore('action', {
  state: (): ActionState => ({
    list: [],
    isLoading: false,
    selected: null,
    viewHtml: '',
    lastKeyword: '',
    keyword: '',
    lastSearchTime: 0,
  }),

  actions: {
    /**
     * 加载动作列表
     */
    async loadList(searchKeyword: string = '') {
      // 如果没有提供搜索关键词，则使用store中的keyword
      const keywordToUse = searchKeyword || this.keyword;

      logger.info('actionStore: loadList with keyword: 🐛', keywordToUse);
      this.lastKeyword = keywordToUse; // 保存当前关键词

      try {
        this.isLoading = true;
        this.list = await actionsApi.getPluginActions(keywordToUse);

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

      return actionsApi.executeAction(action.globalId, this.keyword);
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

    getSelectedAction(): SuperAction | null {
      if (!this.selected) {
        return null;
      }
      const action = this.find(this.selected);
      return action || null;
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
      ipc.removeListener(WindowEvents.ACTIVATED, () => { });
    },

    /**
     * 更新搜索关键词并触发插件动作加载
     */
    async updateKeyword(keyword: string) {
      logger.info(`actionStore: 更新关键词 "${keyword}"，触发插件动作加载`);
      this.keyword = keyword;
      this.lastSearchTime = Date.now();
      await this.loadList(keyword);
    },

    /**
     * 仅设置关键词而不触发其他操作
     */
    setKeyword(keyword: string) {
      logger.info(`actionStore: 设置关键词 "${keyword}" (不触发额外操作)`);
      this.keyword = keyword;
    },

    /**
     * 清除搜索
     */
    clearSearch() {
      this.keyword = '';
      this.loadList('');
    },

    /**
     * 处理键盘事件
     */
    handleKeyDown(event: KeyboardEvent) {
      // 当按下ESC键，清除搜索
      if (event.key === 'Escape') {
        this.clearSearch();
        return;
      }

      // 当按下向下箭头，聚焦到第一个结果
      if (event.key === 'ArrowDown') {
        const firstResult = document.querySelector(
          '.plugin-action-item'
        ) as HTMLElement;
        firstResult?.focus();
      }
    },
  },
});

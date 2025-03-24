import { defineStore } from 'pinia';
import type { PluginAction } from '@/types/plugin-action';

const electronApi = window.electron;
const { actions: actionsApi } = electronApi.plugins;

/**
 * Action 管理 Store
 *
 * 负责管理动作列表、搜索、执行等功能
 */

interface ActionState {
  list: PluginAction[];
  isLoading: boolean;
  selected: string | null;
  viewHtml: string;
}

export const useActionStore = defineStore('action', {
  state: (): ActionState => ({
    list: [],
    isLoading: false,
    selected: null,
    viewHtml: '',
  }),

  actions: {
    /**
     * 加载动作列表
     */
    async loadList(searchKeyword: string = '') {
      console.log('actionStore: loadList with keyword: 🐛', searchKeyword);

      try {
        this.isLoading = true;
        this.list = await actionsApi.getPluginActions(searchKeyword);

        console.log('actionStore: loadList', this.list);
      } catch (error) {
        console.error('actionStore: loadList error: 🐛', error);
        this.list = [];
        throw error;
      } finally {
        this.isLoading = false;
      }
    },

    /**
     * 执行指定动作
     */
    async execute(action: PluginAction): Promise<any> {
      this.selected = action.id;

      if (action.viewPath) {
        await this.loadView(action.id);
      } else {
        this.viewHtml = '';
      }

      return actionsApi.executeAction(action.id);
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
    get(actionId: string, reason: string): PluginAction | undefined {
      console.log('getAction', actionId, 'with reason: 🐛', reason);
      return this.list.find((a) => a.id === actionId);
    },

    getSelectedActionId(): string | null {
      return this.selected || null;
    },

    getActionCount(): number {
      console.log('actionStore: getActionCount', this.list.length);
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

    getActions(): PluginAction[] {
      return this.list;
    },

    hasSelectedAction(): boolean {
      return this.selected !== null;
    },
  },
});

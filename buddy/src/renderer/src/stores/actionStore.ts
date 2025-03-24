import { defineStore } from 'pinia';
import { ref } from 'vue';
import type { PluginAction } from '@/types/plugin-action';

const electronApi = window.electron;
const { actions: actionsApi } = electronApi.plugins;

/**
 * Action 管理 Store
 *
 * 负责管理动作列表、搜索、执行等功能
 */
export const useActionStore = defineStore('action', () => {
  // 状态
  let list: PluginAction[] = [];
  const isLoading = ref(false);
  const selected = ref<PluginAction | null>(null);
  const viewHtml = ref('');

  // Actions
  /**
   * 加载动作列表
   */
  async function loadList(searchKeyword: string = '') {
    console.log('actionStore: loadList with keyword: 🐛', searchKeyword);

    try {
      isLoading.value = true;
      list = await actionsApi.getPluginActions(searchKeyword);

      console.log('actionStore: loadList', list);
    } catch (error) {
      console.error('actionStore: loadList error: 🐛', error);
      list = [];
      throw error;
    } finally {
      isLoading.value = false;
    }
  }

  /**
   * 执行指定动作
   */
  async function execute(action: PluginAction): Promise<any> {
    selected.value = action;

    if (action.viewPath) {
      await loadView(action.id);
    } else {
      viewHtml.value = '';
    }

    return actionsApi.executeAction(action.id);
  }

  /**
   * 加载动作的自定义视图
   */
  async function loadView(actionId: string): Promise<void> {
    try {
      viewHtml.value = '';
      const response = await actionsApi.getActionView(actionId);

      if (response.success && response.html) {
        viewHtml.value = response.html;
      } else if (response.error) {
        throw new Error(response.error);
      }
    } catch (error) {
      viewHtml.value = '';
      throw error;
    }
  }

  /**
   * 根据ID获取动作
   */
  function get(actionId: string, reason: string): PluginAction | undefined {
    console.log('getAction', actionId, 'with reason: 🐛', reason);
    return list.find((a) => a.id === actionId);
  }

  function getSelectedActionId(): string | null {
    return selected.value?.id || null;
  }

  function getActionCount(): number {
    return list.length;
  }

  /**
   * 清空当前选中的动作
   */
  function clearSelected() {
    selected.value = null;
    viewHtml.value = '';
  }

  return {
    // 状态
    list,
    isLoading,
    selected,
    viewHtml,

    // Actions
    loadList,
    execute,
    loadView,
    get,
    getSelectedActionId,
    clearSelected,
    getActionCount,
  };
});

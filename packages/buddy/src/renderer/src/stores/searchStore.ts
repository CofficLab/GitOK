/**
 * searchStore.ts - 搜索状态管理
 *
 * 这个store负责管理应用的搜索相关状态：
 * 1. 搜索关键词
 * 2. 搜索结果的处理
 * 3. 处理插件动作的加载和管理
 *
 * 主要功能：
 * - 管理搜索关键词
 * - 处理搜索结果的更新
 * - 提供搜索状态的响应式访问
 * - 处理插件动作的加载和过滤
 *
 * 状态说明：
 * - keyword: 当前的搜索关键词
 * - pluginActions: 当前加载的插件动作列表
 * - isLoading: 是否正在加载插件动作
 * - selectedActionId: 当前选中的动作ID
 *
 * 注意事项：
 * - 搜索关键词的更新会触发相关组件的重新渲染
 * - 建议使用computed属性来访问搜索状态
 * - 避免直接修改状态，应该使用提供的action
 * - 插件动作的加载和过滤由本store统一管理
 */

import { defineStore } from 'pinia';
import { ref } from 'vue';

export const useSearchStore = defineStore('search', {
  state: () => ({
    keyword: '',
    pluginActions: [] as any[],
    isLoading: false,
    selectedActionId: null as string | null,
  }),

  actions: {
    // 更新搜索关键词并触发插件动作加载
    async updateKeyword(keyword: string) {
      console.log(`searchStore: 更新关键词 "${keyword}"，触发插件动作加载`);
      this.keyword = keyword;
      await this.loadPluginActions();
    },

    // 仅设置关键词而不触发其他操作
    setKeyword(keyword: string) {
      console.log(`searchStore: 设置关键词 "${keyword}" (不触发额外操作)`);
      this.keyword = keyword;
    },

    // 加载插件动作
    async loadPluginActions() {
      console.log(`searchStore: 加载插件动作, 关键词: "${this.keyword}"`);
      this.isLoading = true;

      try {
        const actions = await window.electron.plugins.getPluginActions(
          this.keyword
        );
        console.log(`searchStore: 加载到 ${actions.length} 个插件动作`);
        this.pluginActions = actions;
      } catch (error) {
        console.error('searchStore: 加载插件动作失败', error);
        this.pluginActions = [];
      } finally {
        this.isLoading = false;
      }
    },

    // 更新插件动作列表（由外部调用，如App.vue）
    updatePluginActions(actions: any[]) {
      this.pluginActions = actions;
    },

    // 选择一个动作
    selectAction(actionId: string | null) {
      this.selectedActionId = actionId;
    },

    // 清除选中的动作
    clearSelectedAction() {
      this.selectedActionId = null;
    },

    // 处理键盘事件
    handleKeyDown(event: KeyboardEvent) {
      if (event.key === 'ArrowDown') {
        // 焦点移到第一个结果
        const firstResult = document.querySelector(
          '.results-container li a'
        ) as HTMLElement;
        firstResult?.focus();
      }
    },
  },
});

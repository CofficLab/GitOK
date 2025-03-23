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
import type { PluginAction } from '../components/PluginManager.vue';

export const useSearchStore = defineStore('search', {
  state: () => ({
    keyword: '',
    pluginActions: [] as PluginAction[],
    isLoading: false,
    selectedActionId: null as string | null,
    lastSearchTime: 0, // 记录最后一次搜索时间
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
      // 记录本次搜索时间
      const currentSearchTime = Date.now();
      this.lastSearchTime = currentSearchTime;

      console.log(`searchStore: 加载插件动作, 关键词: "${this.keyword}"`);
      this.isLoading = true;

      try {
        console.log(
          `searchStore: 调用 window.electron.plugins.getPluginActions("${this.keyword}")`
        );
        const response = await window.electron.plugins.getPluginActions(
          this.keyword
        );
        console.log(`searchStore: 获取到响应:`, response);

        // 确保这是最新的搜索请求（防止旧的请求覆盖新的结果）
        if (currentSearchTime !== this.lastSearchTime) {
          console.log(
            `searchStore: 忽略过时的搜索结果，当前时间: ${currentSearchTime}，最新时间: ${this.lastSearchTime}`
          );
          return;
        }

        // 检查返回格式并提取动作数组
        let actions: PluginAction[] = [];
        if (Array.isArray(response)) {
          console.log(`searchStore: 响应是数组格式`);
          actions = response as PluginAction[];
        } else if (response && typeof response === 'object') {
          console.log(`searchStore: 响应是对象格式:`, response);
          if ('actions' in response && Array.isArray(response.actions)) {
            console.log(`searchStore: 从response.actions提取数组`);
            actions = response.actions as PluginAction[];
          } else if (
            'success' in response &&
            response.success === true &&
            'actions' in response
          ) {
            console.log(
              `searchStore: 从response.actions提取数组(success检查通过)`
            );
            actions = response.actions as PluginAction[];
          } else {
            console.log(`searchStore: 无法从响应中提取动作数组，使用空数组`);
          }
        } else {
          console.log(`searchStore: 响应不是数组或对象:`, response);
        }

        // 强制渲染更新 - 即使是空数组也要更新
        console.log(
          `searchStore: 最终加载到 ${actions.length} 个插件动作:`,
          actions
        );
        this.pluginActions = [...actions];

        // 如果没有搜索结果但有关键词，显示一个友好的提示
        if (actions.length === 0 && this.keyword) {
          console.log(`searchStore: 没有找到匹配 "${this.keyword}" 的动作`);
        }
      } catch (error) {
        console.error('searchStore: 加载插件动作失败', error);
        this.pluginActions = [];
      } finally {
        this.isLoading = false;
      }
    },

    // 更新插件动作列表（由外部调用，如App.vue）
    updatePluginActions(actions: PluginAction[]) {
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

    // 清除搜索
    clearSearch() {
      this.keyword = '';
      this.pluginActions = [];
      this.selectedActionId = null;
    },

    // 处理键盘事件
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

/**
 * searchStore.ts - 搜索状态管理
 *
 * 这个store负责管理应用的搜索相关状态：
 * 1. 搜索关键词
 * 2. 搜索结果的处理
 *
 * 主要功能：
 * - 管理搜索关键词
 * - 处理搜索结果的更新
 * - 提供搜索状态的响应式访问
 *
 * 状态说明：
 * - keyword: 当前的搜索关键词
 *
 * 注意事项：
 * - 搜索关键词的更新会触发相关组件的重新渲染
 * - 建议使用computed属性来访问搜索状态
 * - 避免直接修改状态，应该使用提供的action
 */

import { defineStore } from 'pinia';

export const useSearchStore = defineStore('search', {
  state: () => ({
    keyword: '',
    pluginActions: [] as any[],
  }),

  actions: {
    // 更新搜索关键词
    async updateKeyword(keyword: string) {
      this.keyword = keyword;
      console.log(`触发插件管理系统, 关键字: ${keyword}`);
      // 这里可以触发其他相关操作
    },

    // 更新插件动作列表
    updatePluginActions(actions: any[]) {
      this.pluginActions = actions;
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

    setKeyword(keyword: string) {
      this.keyword = keyword;
    },
  },
});

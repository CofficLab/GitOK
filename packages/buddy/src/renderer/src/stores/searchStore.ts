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
  },
});

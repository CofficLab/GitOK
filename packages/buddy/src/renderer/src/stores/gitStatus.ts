import { defineStore } from 'pinia';

export const useGitStatusStore = defineStore('gitStatus', {
  state: () => ({
    gitRepo: 'GitOK',
    branch: 'main',
    commits: 128,
    lastUpdated: '10分钟前',
  }),

  actions: {
    updateStatus(
      status: Partial<{
        gitRepo: string;
        branch: string;
        commits: number;
        lastUpdated: string;
      }>
    ) {
      Object.assign(this, status);
    },
  },
});

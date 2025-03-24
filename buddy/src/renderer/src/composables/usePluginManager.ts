import { PluginAction } from '@/types/plugin-action';
import { ref, computed } from 'vue';

const electronApi = window.electron;
const pluginsApi = electronApi.plugins;
const actionsApi = pluginsApi.actions;

export function usePluginManager() {
  // 存储从主进程获取的插件动作数据
  const pluginActions = ref<PluginAction[]>([]);
  // 存储当前的搜索关键词
  const currentKeyword = ref('');
  // 存储是否正在加载动作
  const isLoadingActions = ref(false);
  // 存储当前选中的动作
  const selectedAction = ref<PluginAction | null>(null);
  // 存储当前动作的自定义视图HTML
  const actionViewHtml = ref('');

  // 加载插件动作
  const loadPluginActions = async (
    keyword: string = ''
  ): Promise<PluginAction[]> => {
    try {
      isLoadingActions.value = true;
      currentKeyword.value = keyword;

      const actions = await actionsApi.getPluginActions(keyword);
      pluginActions.value = actions;
      return actions;
    } catch (error) {
      pluginActions.value = [];
      return [];
    } finally {
      isLoadingActions.value = false;
    }
  };

  // 执行插件动作
  const executePluginAction = async (action: PluginAction): Promise<any> => {
    try {
      // 设置当前选中的动作
      selectedAction.value = action;

      // 如果动作有自定义视图，加载视图内容
      if (action.viewPath) {
        await loadActionView(action.id);
      } else {
        actionViewHtml.value = '';
      }

      const result = await actionsApi.executeAction(action.id);
      return result;
    } catch (error) {
      throw error;
    }
  };

  // 加载动作的自定义视图
  const loadActionView = async (actionId: string): Promise<void> => {
    try {
      // 清空之前的视图HTML
      actionViewHtml.value = '';

      const response = await actionsApi.getActionView(actionId);

      if (response.success && response.html) {
        // 确保设置HTML内容
        actionViewHtml.value = response.html;

        // 再次确认HTML内容已设置
        if (!actionViewHtml.value) {
          throw new Error('设置视图HTML失败');
        }
      } else {
        actionViewHtml.value = '';
        if (response.error) {
          throw new Error(response.error);
        }
      }
    } catch (error) {
      actionViewHtml.value = '';
      throw error;
    }
  };

  // 计算属性
  const actionsComputed = computed(() => pluginActions.value);
  const keywordComputed = computed(() => currentKeyword.value);
  const isLoadingComputed = computed(() => isLoadingActions.value);
  const selectedActionComputed = computed(() => selectedAction.value);
  const actionViewHtmlComputed = computed(() => actionViewHtml.value);

  // 返回插件管理器接口
  const pluginManagerAPI = {
    // 获取动作列表
    get actions() {
      return actionsComputed.value;
    },

    // 当前关键词
    get keyword() {
      return keywordComputed.value;
    },

    // 是否正在加载
    get isLoading() {
      return isLoadingComputed.value;
    },

    // 当前选中的动作
    get selectedAction() {
      return selectedActionComputed.value;
    },

    // 当前动作的自定义视图HTML
    get actionViewHtml() {
      return actionViewHtmlComputed.value;
    },

    // 获取动作
    getAction: (actionId: string, reason: string) => {
      console.log('getAction', actionId, 'with reason: 🐛', reason);
      return pluginActions.value.find((a) => a.id === actionId);
    },

    // 加载动作
    loadActions: loadPluginActions,

    // 执行动作
    executeAction: executePluginAction,

    // 加载动作视图
    loadActionView: loadActionView,
  };

  return pluginManagerAPI;
}

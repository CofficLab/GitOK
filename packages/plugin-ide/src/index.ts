import { Logger } from './utils/logger';
import { ExecuteActionArgs, ExecuteResult, GetActionsArgs, SuperAction, SuperPlugin } from '@coffic/buddy-types';
import { IDEServiceFactory } from './services/ide_factory';

const logger = new Logger('IDE工作空间');

/**
 * IDE工作空间插件
 * 用于显示当前IDE的工作空间信息
 * 提供打开工作区文件浏览器的功能
 * 工作区路径会被缓存到本地文件
 */
const plugin: SuperPlugin = {
	name: 'IDE工作空间',
	description: '显示当前IDE的工作空间信息',
	version: '1.0.0',
	author: 'Coffic',
	id: '',
	path: '',
	type: 'user',

	/**
	 * 获取插件提供的动作列表
	 * 
	 * @param args 获取动作列表的参数
	 * @returns 动作列表
	 */
	async getActions(args: GetActionsArgs): Promise<SuperAction[]> {
		logger.info(`获取动作列表，关键词: "${args.keyword}", 应用: "${args.overlaidApp}"`);

		// 检查是否为支持的IDE并创建对应的服务实例
		const ideService = IDEServiceFactory.createService(args.overlaidApp || '');
		if (!ideService) {
			logger.debug('不是支持的IDE，返回空列表');
			return [];
		}

		// 保存当前应用ID到缓存
		await IDEServiceFactory.saveCurrentApp(args.overlaidApp || '');

		// 预先获取工作空间信息
		const workspace = await ideService.getWorkspace();

		// 将工作区路径缓存到文件中
		if (workspace) {
			await IDEServiceFactory.saveWorkspace(args.overlaidApp || '', workspace);
		}

		const workspaceInfo = workspace
			? `当前工作空间: ${workspace}`
			: `未能获取到 ${args.overlaidApp || ''} 的工作空间信息`;

		// 创建动作列表
		const actions: SuperAction[] = [
			{
				id: 'show_workspace',
				description: workspaceInfo,
				icon: '📁',
				globalId: '',
				pluginId: '',
			},
		];

		// 仅当工作区存在时添加打开文件浏览器的动作
		if (workspace) {
			actions.push({
				id: 'open_in_explorer',
				description: `在文件浏览器中打开: ${workspace}`,
				icon: '🔍',
				globalId: '',
				pluginId: '',
			});

			// 检查是否为Git仓库，如果是，检查是否有未提交的更改
			if (await IDEServiceFactory.isGitRepository(workspace)) {
				// 添加Git相关动作
				const hasChanges = await IDEServiceFactory.hasUncommittedChanges(workspace);
				if (hasChanges) {
					// 当前分支名称
					const branch = await IDEServiceFactory.getCurrentBranch(workspace);
					actions.push({
						id: 'git_commit_push',
						description: `将未提交的更改提交并推送到${branch}分支`,
						icon: '🚀',
						globalId: '',
						pluginId: '',
					});
				}
			}
		}

		// 如果有关键词，过滤匹配的动作
		if (args.keyword) {
			const lowerKeyword = args.keyword.toLowerCase();
			const filteredActions = actions.filter(
				(action) => action.description.toLowerCase().includes(lowerKeyword)
			);

			logger.info(`过滤后返回 ${filteredActions.length} 个动作`);
			return filteredActions;
		}

		return actions;
	},

	/**
	 * 执行插件动作
	 * 
	 * @param args 执行动作的参数
	 * @returns 动作执行结果
	 */
	async executeAction(args: ExecuteActionArgs): Promise<ExecuteResult> {
		logger.info(`执行动作: ${args.actionId} (${args.keyword})`);

		try {
			// 从缓存中获取工作区路径
			// 不需要提供应用ID，会自动使用缓存中的当前应用ID
			const workspace = IDEServiceFactory.getWorkspace();

			if (!workspace) {
				const currentApp = IDEServiceFactory.getCurrentApp();
				logger.error(`无法从缓存获取工作区路径，应用ID: ${currentApp}`);

				if (currentApp) {
					// 尝试重新获取工作区路径
					const ideService = IDEServiceFactory.createService(currentApp);
					if (ideService) {
						const freshWorkspace = await ideService.getWorkspace();
						if (freshWorkspace) {
							// 重新缓存工作区路径
							await IDEServiceFactory.saveWorkspace(currentApp, freshWorkspace);

							// 继续执行动作
							return this.executeAction(args);
						}
					}
				}

				return { success: false, message: `无法获取工作区路径，请重新打开IDE` };
			}

			switch (args.actionId) {
				case 'show_workspace': {
					return { success: true, message: `当前工作空间: ${workspace}` };
				}

				case 'open_in_explorer': {
					const result = await IDEServiceFactory.openInExplorer(workspace);
					return { success: true, message: result };
				}

				case 'git_commit_push': {
					const result = await IDEServiceFactory.autoCommitAndPush(workspace);
					return { success: true, message: result };
				}

				default:
					return { success: false, message: `未知的动作: ${args.actionId}` };
			}
		} catch (error: any) {
			logger.error(`执行动作失败:`, error);
			return { success: false, message: `执行失败: ${error.message || '未知错误'}` };
		}
	},
};

// 插件初始化输出
logger.info(`IDE工作空间插件已加载: ${plugin.name} v${plugin.version}`);

// 导出插件
export = plugin;

/**
 * Git Helper测试入口文件
 * 用于直接获取当前IDE的工作空间信息和Git状态
 */
import { VSCodeService } from './services/vscode';
import { CursorService } from './services/cursor';
import { GitService } from './services/git';

/**
 * 主函数
 */
async function main() {
  console.log('===== Git Helper检测工具 =====');
  console.log('正在获取IDE工作空间信息和Git状态...\n');

  // VSCode工作空间服务
  const vscodeService = new VSCodeService();
  try {
    const vscodeWorkspace = await vscodeService.getWorkspace();
    console.log(`📂 VSCode 工作空间: ${vscodeWorkspace}`);

    if (vscodeWorkspace) {
      await checkGitStatus(vscodeWorkspace, 'VSCode');
    }
  } catch (err: any) {
    console.error(`❌ VSCode服务出错: ${err.message}`);
  }

  // Cursor工作空间服务
  const cursorService = new CursorService();
  try {
    const cursorWorkspace = await cursorService.getWorkspace();
    console.log(`📂 Cursor 工作空间: ${cursorWorkspace}`);

    if (cursorWorkspace) {
      await checkGitStatus(cursorWorkspace, 'Cursor');
    }
  } catch (err: any) {
    console.error(`❌ Cursor服务出错: ${err.message}`);
  }

  console.log('\n===== 检测完成 =====');
}

/**
 * 检查Git状态
 */
async function checkGitStatus(workspacePath: string, source: string) {
  const gitService = new GitService(workspacePath);

  try {
    const isRepo = await gitService.isGitRepository();
    if (!isRepo) {
      console.log(`🚫 ${source} 工作空间不是Git仓库`);
      return;
    }

    const status = await gitService.getStatus();
    const changesDescription = await gitService.getChangesDescription();

    console.log(`✅ ${source} 工作空间是Git仓库`);
    console.log(`📊 当前分支: ${status.branch}`);
    console.log(`📝 变更文件数: ${status.changedFilesCount}`);

    if (status.hasChanges) {
      console.log(`🔄 变更详情: ${changesDescription}`);
    }

    if (status.hasUnpushedCommits) {
      console.log(`⚠️ 有未推送的提交`);
    }

    if (status.hasChanges) {
      console.log(`\n🚀 测试提交并推送...`);
      const result = await gitService.commitAndPush();
      console.log(`结果: ${result.message}`);
    }
  } catch (err: any) {
    console.error(`❌ Git服务出错: ${err.message}`);
  }
}

// 执行主函数
main().catch((err: any) => {
  console.error('❌ 执行过程中发生错误:', err);
});

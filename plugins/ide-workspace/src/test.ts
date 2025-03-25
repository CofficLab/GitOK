/**
 * IDE工作空间测试入口文件
 * 用于直接获取当前IDE的工作空间信息
 */
import { VSCodeService } from './services/vscode';
import { CursorService } from './services/cursor';

/**
 * 主函数
 */
async function main() {
  console.log('===== IDE工作空间检测工具 =====');
  console.log('正在获取IDE工作空间信息...\n');

  // VSCode工作空间服务
  const vscodeService = new VSCodeService();
  try {
    const vscodeWorkspace = await vscodeService.getWorkspace();
    console.log(`📂 VSCode 工作空间: ${vscodeWorkspace}`);
  } catch (err: any) {
    console.error(`❌ VSCode服务出错: ${err.message}`);
  }

  // Cursor工作空间服务
  const cursorService = new CursorService();
  try {
    const cursorWorkspace = await cursorService.getWorkspace();
    console.log(`📂 Cursor 工作空间: ${cursorWorkspace}`);
  } catch (err: any) {
    console.error(`❌ Cursor服务出错: ${err.message}`);
  }

  console.log('\n===== 检测完成 =====');
}

// 执行主函数
main().catch((err: any) => {
  console.error('❌ 执行过程中发生错误:', err);
});

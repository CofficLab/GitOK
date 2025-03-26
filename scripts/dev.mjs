#!/usr/bin/env node

import inquirer from 'inquirer';
import { execSync } from 'child_process';

// 定义可用的项目及其对应的开发命令
const projects = [
  {
    name: 'Electron 应用 (buddy)',
    value: 'buddy',
    command: 'pnpm --filter buddy dev',
  },
  {
    name: 'VSCode 扩展 (vsc_extension)',
    value: 'vsc_extension',
    command: 'pnpm --filter vsc_extension dev',
  },
  {
    name: 'MCP Core (mcp-core)',
    value: 'mcp-core',
    command: 'pnpm --filter mcp-core dev',
  },
  {
    name: 'IDE工作空间插件 (ide-workspace)',
    value: 'ide-workspace',
    command: 'pnpm --filter @gitok/plugin-ide-workspace watch',
  },
];

async function buildDependencies(steps) {
  if (!steps || steps.length === 0) return;

  console.log('\n🔨 正在构建依赖包...');

  for (const step of steps) {
    try {
      process.stdout.write(`📦 构建 ${step.name}...`);
      // 使用 stdio: 'ignore' 来隐藏构建输出
      execSync(step.command, { stdio: ['ignore', 'ignore', 'pipe'] });
      process.stdout.clearLine(0);
      process.stdout.cursorTo(0);
      console.log(`✅ ${step.name} 构建成功`);
    } catch (error) {
      process.stdout.clearLine(0);
      process.stdout.cursorTo(0);
      console.error(`❌ ${step.name} 构建失败`);
      if (error.stderr) {
        console.error(error.stderr.toString());
      }
      throw error;
    }
  }
  console.log(''); // 添加一个空行作为分隔
}

async function main() {
  try {
    const { project } = await inquirer.prompt([
      {
        type: 'list',
        name: 'project',
        message: '请选择要开发的项目：',
        choices: projects,
      },
    ]);

    const selectedProject = projects.find((p) => p.value === project);

    // 如果有预构建步骤，先执行它们
    if (selectedProject.preDevSteps) {
      await buildDependencies(selectedProject.preDevSteps);
    }

    console.log(`\n🚀 启动 ${selectedProject.name} 的开发环境...\n`);

    // 执行对应的命令
    execSync(selectedProject.command, { stdio: 'inherit' });
  } catch (error) {
    console.error('\n❌ 发生错误：', error);
    process.exit(1);
  }
}

main();

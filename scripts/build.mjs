#!/usr/bin/env node

import inquirer from 'inquirer';
import { execSync } from 'child_process';
import { dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

// 定义可构建的项目
const projects = [
  {
    name: '所有项目',
    value: 'all',
    command: 'pnpm -r build',
  },
  {
    name: 'Electron 应用 (buddy)',
    value: 'buddy',
    command: 'pnpm --filter buddy build',
    preBuildSteps: [
      {
        name: '@coffic/active-app-monitor',
        command: 'pnpm --filter active-app-monitor build',
      },
      {
        name: '@coffic/command-key-listener',
        command: 'pnpm --filter command-key-listener build',
      },
    ],
  },
  {
    name: 'Buddy - 构建 Windows 应用',
    value: 'buddy:win',
    command: 'pnpm --filter buddy build:win',
    preBuildSteps: [
      {
        name: '@coffic/active-app-monitor',
        command: 'pnpm --filter active-app-monitor build',
      },
      {
        name: '@coffic/command-key-listener',
        command: 'pnpm --filter command-key-listener build',
      },
    ],
  },
  {
    name: 'Buddy - 构建 macOS 应用',
    value: 'buddy:mac',
    command: 'pnpm --filter buddy build:mac',
    preBuildSteps: [
      {
        name: '@coffic/active-app-monitor',
        command: 'pnpm --filter active-app-monitor build',
      },
      {
        name: '@coffic/command-key-listener',
        command: 'pnpm --filter command-key-listener build',
      },
    ],
  },
  {
    name: 'Buddy - 构建 Linux 应用',
    value: 'buddy:linux',
    command: 'pnpm --filter buddy build:linux',
    preBuildSteps: [
      {
        name: '@coffic/active-app-monitor',
        command: 'pnpm --filter active-app-monitor build',
      },
      {
        name: '@coffic/command-key-listener',
        command: 'pnpm --filter command-key-listener build',
      },
    ],
  },
  {
    name: 'VSCode 扩展 (vsc_extension)',
    value: 'vsc_extension',
    command: 'pnpm --filter vsc_extension build',
  },
  {
    name: 'MCP Core (mcp-core)',
    value: 'mcp-core',
    command: 'pnpm --filter mcp-core build',
  },
  {
    name: 'Active App Monitor',
    value: 'active-app-monitor',
    command: 'pnpm --filter active-app-monitor build',
  },
  {
    name: 'Command Key Listener',
    value: 'command-key-listener',
    command: 'pnpm --filter command-key-listener build',
    buildSteps: [
      {
        name: 'TypeScript 编译',
        command: 'pnpm --filter command-key-listener build:ts',
      },
      {
        name: 'Native 模块编译',
        command: 'pnpm --filter command-key-listener build:native',
      },
    ],
  },
  {
    name: 'IDE工作空间插件 (ide-workspace)',
    value: 'ide-workspace',
    command: 'pnpm --filter @gitok/plugin-ide-workspace build',
    buildSteps: [
      {
        name: 'TypeScript 编译',
        command: 'pnpm --filter @gitok/plugin-ide-workspace build',
      },
    ],
  },
];

async function buildDependencies(steps) {
  if (!steps || steps.length === 0) return;

  console.log('\n🔨 正在构建依赖包...');

  for (const step of steps) {
    try {
      process.stdout.write(`📦 构建 ${step.name}...`);
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

async function buildStepByStep(steps) {
  if (!steps || steps.length === 0) return;

  for (const step of steps) {
    try {
      process.stdout.write(`⚙️ ${step.name}...`);
      execSync(step.command, { stdio: ['ignore', 'ignore', 'pipe'] });
      process.stdout.clearLine(0);
      process.stdout.cursorTo(0);
      console.log(`✅ ${step.name} 完成`);
    } catch (error) {
      process.stdout.clearLine(0);
      process.stdout.cursorTo(0);
      console.error(`❌ ${step.name} 失败`);
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
        message: '请选择要构建的项目：',
        choices: projects,
      },
    ]);

    const selectedProject = projects.find((p) => p.value === project);

    // 如果有预构建步骤，先执行它们
    if (selectedProject.preBuildSteps) {
      await buildDependencies(selectedProject.preBuildSteps);
    }

    console.log(`\n🏗️  正在构建 ${selectedProject.name}...\n`);

    // 如果项目有多个构建步骤，逐步执行
    if (selectedProject.buildSteps) {
      await buildStepByStep(selectedProject.buildSteps);
    } else {
      // 执行单个构建命令
      execSync(selectedProject.command, { stdio: 'inherit' });
    }

    console.log(`\n✨ ${selectedProject.name} 构建完成！`);
  } catch (error) {
    console.error('\n❌ 构建失败：', error);
    process.exit(1);
  }
}

main();

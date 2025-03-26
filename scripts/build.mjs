#!/usr/bin/env node

/**
 * @fileoverview 项目构建脚本
 *
 * 这个脚本提供了一个灵活的构建系统，支持：
 * - 交互式选择要构建的项目
 * - 命令行参数直接指定构建项目
 * - CI/CD 环境中的自动化构建
 *
 * 使用方式：
 * 1. 交互模式：
 *    ```bash
 *    node scripts/build.mjs
 *    ```
 *
 * 2. CI 模式：
 *    ```bash
 *    node scripts/build.mjs buddy:mac
 *    ```
 *
 * 3. 作为模块导入：
 *    ```javascript
 *    import { buildProject } from './scripts/build.mjs';
 *    await buildProject('buddy:mac');
 *    ```
 */

import inquirer from 'inquirer';
import { execSync } from 'child_process';
import { dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

/**
 * @typedef {Object} BuildStep
 * @property {string} name - 构建步骤的名称
 * @property {string} command - 要执行的构建命令
 */

/**
 * @typedef {Object} Project
 * @property {string} name - 项目显示名称
 * @property {string} value - 项目唯一标识符
 * @property {string} command - 主构建命令
 * @property {BuildStep[]} [preBuildSteps] - 前置构建步骤（如依赖项构建）
 * @property {BuildStep[]} [buildSteps] - 详细构建步骤（如分步骤构建）
 */

/** @type {Project[]} */
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

/**
 * 构建项目依赖
 * 在主构建过程开始前，执行所有必要的依赖项构建
 *
 * @param {BuildStep[]} steps - 要执行的构建步骤
 * @throws {Error} 当构建步骤失败时抛出错误
 */
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

/**
 * 逐步执行构建步骤
 * 用于需要多个步骤的复杂构建过程
 *
 * @param {BuildStep[]} steps - 要执行的构建步骤
 * @throws {Error} 当任何构建步骤失败时抛出错误
 */
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

/**
 * 构建指定的项目
 *
 * @param {string} projectValue - 项目的唯一标识符
 * @throws {Error} 当项目不存在或构建失败时抛出错误
 */
async function buildProject(projectValue) {
  const selectedProject = projects.find((p) => p.value === projectValue);
  if (!selectedProject) {
    throw new Error(`未找到项目: ${projectValue}`);
  }

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
}

/**
 * 主函数
 * 处理命令行参数并执行相应的构建过程
 *
 * @throws {Error} 当构建过程中发生错误时抛出
 */
async function main() {
  try {
    // 检查是否有命令行参数
    const projectArg = process.argv[2];

    if (projectArg) {
      // CI 模式：直接构建指定项目
      await buildProject(projectArg);
    } else {
      // 交互模式：提示用户选择项目
      const { project } = await inquirer.prompt([
        {
          type: 'list',
          name: 'project',
          message: '请选择要构建的项目：',
          choices: projects,
        },
      ]);
      await buildProject(project);
    }
  } catch (error) {
    console.error('\n❌ 构建失败：', error);
    process.exit(1);
  }
}

// 如果是直接运行此脚本（不是被导入）
if (import.meta.url === `file://${fileURLToPath(import.meta.url)}`) {
  main();
}

// 导出供其他模块使用
export { buildProject, projects };

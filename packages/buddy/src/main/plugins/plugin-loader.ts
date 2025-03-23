/**
 * 插件加载器
 * 负责发现、加载和管理插件
 */
import { app } from 'electron';
import fs from 'fs';
import path from 'path';
import { exec } from 'child_process';
import { Plugin, PluginPackage } from './types';
import { Logger } from '../utils/Logger';

// 插件目录
const PLUGIN_DIR = path.join(app.getPath('userData'), 'plugins');
const LOCAL_PLUGIN_DIR = path.join(__dirname, '../../../plugins');

// 创建日志记录器
const logger = new Logger('PluginLoader');

// 确保插件目录存在
function ensurePluginDirs() {
  logger.debug('检查插件目录是否存在');

  if (!fs.existsSync(PLUGIN_DIR)) {
    logger.info(`创建插件目录: ${PLUGIN_DIR}`);
    fs.mkdirSync(PLUGIN_DIR, { recursive: true });
  } else {
    logger.debug(`插件目录已存在: ${PLUGIN_DIR}`);
  }
}

/**
 * 加载本地插件（来自packages目录）
 */
export async function loadLocalPlugins(): Promise<Plugin[]> {
  const plugins: Plugin[] = [];

  logger.info(`开始加载本地插件，目录: ${LOCAL_PLUGIN_DIR}`);

  // 检查本地插件目录是否存在
  if (!fs.existsSync(LOCAL_PLUGIN_DIR)) {
    logger.info('本地插件目录不存在', { path: LOCAL_PLUGIN_DIR });
    return plugins;
  }

  try {
    // 读取packages目录中所有文件夹
    const entries = fs.readdirSync(LOCAL_PLUGIN_DIR, { withFileTypes: true });
    const pluginFolders = entries.filter((entry) => entry.isDirectory());

    logger.info(`发现 ${pluginFolders.length} 个可能的插件文件夹`);

    for (const folder of pluginFolders) {
      const pluginDir = path.join(LOCAL_PLUGIN_DIR, folder.name);
      const packageJsonPath = path.join(pluginDir, 'package.json');

      logger.debug(`检查文件夹: ${folder.name}`);

      // 检查是否存在package.json
      if (!fs.existsSync(packageJsonPath)) {
        logger.debug(`跳过 ${folder.name}: 没有package.json`);
        continue;
      }

      try {
        // 读取package.json
        const packageJson = JSON.parse(
          fs.readFileSync(packageJsonPath, 'utf-8')
        ) as PluginPackage;
        logger.debug(
          `解析 ${folder.name} 的 package.json: ${packageJson.name}@${packageJson.version}`
        );

        // 检查是否是GitOK插件
        if (!packageJson.gitokPlugin) {
          logger.debug(
            `跳过 ${folder.name}: 不是GitOK插件（缺少gitokPlugin字段）`
          );
          continue;
        }

        // 加载插件
        const mainPath = path.join(pluginDir, packageJson.main);
        if (!fs.existsSync(mainPath)) {
          logger.error(`插件主文件不存在: ${mainPath}`);
          continue;
        }

        logger.info(
          `开始加载插件: ${packageJson.name} (${packageJson.gitokPlugin.id})`
        );

        // 动态导入插件
        try {
          // 使用相对路径，避免Node.js解析问题
          const relativePath = path.relative(__dirname, mainPath);
          logger.debug(`相对路径: ${relativePath}`);

          // 使用绝对路径导入插件模块
          const absolutePath = path.resolve(__dirname, relativePath);
          logger.debug(`绝对路径: ${absolutePath}`);

          // eslint-disable-next-line @typescript-eslint/no-var-requires
          const pluginModule = require(absolutePath);
          logger.debug(`已加载插件模块: ${typeof pluginModule}`);

          // 输出插件模块结构以进行调试
          logger.debug(
            `插件模块结构: ${JSON.stringify(Object.keys(pluginModule))}`
          );

          // 检查插件模块是否直接导出对象
          let plugin: Plugin;
          if (
            typeof pluginModule === 'object' &&
            pluginModule.id &&
            pluginModule.getActions
          ) {
            logger.debug(`使用模块直接导出的对象作为插件`);
            plugin = pluginModule;
          } else if (pluginModule.default) {
            logger.debug(`使用默认导出 (default) 作为插件`);
            plugin = pluginModule.default;
          } else if (pluginModule.createPlugin) {
            logger.debug(`使用createPlugin函数创建插件`);
            plugin = pluginModule.createPlugin();
          } else {
            logger.error(`插件 ${packageJson.name} 没有正确的导出格式`);
            logger.debug(
              `插件模块内容: ${JSON.stringify(
                pluginModule,
                (key, value) => {
                  if (typeof value === 'function') return 'function';
                  return value;
                },
                2
              )}`
            );
            continue;
          }

          // 验证插件结构
          if (
            !plugin.id ||
            !plugin.name ||
            !plugin.getActions ||
            !plugin.executeAction
          ) {
            logger.error(
              `插件 ${packageJson.name} 结构不完整，缺少必要的属性或方法`
            );
            logger.debug(
              `插件对象结构: ${JSON.stringify(Object.keys(plugin))}`
            );
            continue;
          }

          // 添加到插件列表
          plugins.push(plugin);
          logger.info(`成功加载本地插件: ${plugin.name} (${plugin.id})`);
        } catch (err) {
          logger.error(`加载插件模块失败: ${mainPath}`, {
            error: err instanceof Error ? err.message : String(err),
          });
        }
      } catch (err) {
        logger.error(`解析插件package.json失败: ${packageJsonPath}`, {
          error: err instanceof Error ? err.message : String(err),
        });
      }
    }
  } catch (err) {
    logger.error('加载本地插件失败', {
      error: err instanceof Error ? err.message : String(err),
    });
  }

  logger.info(`加载了 ${plugins.length} 个本地插件`);
  return plugins;
}

/**
 * 加载已安装的插件
 */
export async function loadInstalledPlugins(): Promise<Plugin[]> {
  const plugins: Plugin[] = [];

  logger.info(`开始加载已安装插件，目录: ${PLUGIN_DIR}`);
  ensurePluginDirs();

  try {
    // 读取插件目录中所有文件夹
    const entries = fs.readdirSync(PLUGIN_DIR, { withFileTypes: true });
    const pluginFolders = entries.filter((entry) => entry.isDirectory());

    logger.info(`发现 ${pluginFolders.length} 个可能的已安装插件文件夹`);

    for (const folder of pluginFolders) {
      const pluginDir = path.join(PLUGIN_DIR, folder.name);
      const packageJsonPath = path.join(pluginDir, 'package.json');

      logger.debug(`检查已安装文件夹: ${folder.name}`);

      // 检查是否存在package.json
      if (!fs.existsSync(packageJsonPath)) {
        logger.debug(`跳过 ${folder.name}: 没有package.json`);
        continue;
      }

      try {
        // 读取package.json
        const packageJson = JSON.parse(
          fs.readFileSync(packageJsonPath, 'utf-8')
        ) as PluginPackage;
        logger.debug(
          `解析 ${folder.name} 的 package.json: ${packageJson.name}@${packageJson.version}`
        );

        // 检查是否是GitOK插件
        if (!packageJson.gitokPlugin) {
          logger.debug(
            `跳过 ${folder.name}: 不是GitOK插件（缺少gitokPlugin字段）`
          );
          continue;
        }

        // 加载插件
        const mainPath = path.join(pluginDir, packageJson.main);
        if (!fs.existsSync(mainPath)) {
          logger.error(`插件主文件不存在: ${mainPath}`);
          continue;
        }

        logger.info(
          `开始加载已安装插件: ${packageJson.name} (${packageJson.gitokPlugin.id})`
        );

        try {
          // 使用绝对路径导入
          logger.debug(`插件绝对路径: ${mainPath}`);

          // eslint-disable-next-line @typescript-eslint/no-var-requires
          const pluginModule = require(mainPath);
          logger.debug(`已加载已安装插件模块: ${typeof pluginModule}`);

          // 输出插件模块结构以进行调试
          logger.debug(
            `插件模块结构: ${JSON.stringify(Object.keys(pluginModule))}`
          );

          // 检查插件模块是否直接导出对象
          let plugin: Plugin;
          if (
            typeof pluginModule === 'object' &&
            pluginModule.id &&
            pluginModule.getActions
          ) {
            logger.debug(`使用模块直接导出的对象作为插件`);
            plugin = pluginModule;
          } else if (pluginModule.default) {
            logger.debug(`使用默认导出作为插件`);
            plugin = pluginModule.default;
          } else if (pluginModule.createPlugin) {
            logger.debug(`使用createPlugin函数创建插件`);
            plugin = pluginModule.createPlugin();
          } else {
            logger.error(`插件 ${packageJson.name} 没有正确的导出格式`);
            continue;
          }

          // 验证插件结构
          if (
            !plugin.id ||
            !plugin.name ||
            !plugin.getActions ||
            !plugin.executeAction
          ) {
            logger.error(
              `插件 ${packageJson.name} 结构不完整，缺少必要的属性或方法`
            );
            logger.debug(
              `插件对象结构: ${JSON.stringify(Object.keys(plugin))}`
            );
            continue;
          }

          // 添加到插件列表
          plugins.push(plugin);
          logger.info(`成功加载已安装插件: ${plugin.name} (${plugin.id})`);
        } catch (err) {
          logger.error(`加载插件模块失败: ${mainPath}`, {
            error: err instanceof Error ? err.message : String(err),
          });
        }
      } catch (err) {
        logger.error(`解析插件package.json失败: ${packageJsonPath}`, {
          error: err instanceof Error ? err.message : String(err),
        });
      }
    }
  } catch (err) {
    logger.error('加载已安装插件失败', {
      error: err instanceof Error ? err.message : String(err),
    });
  }

  logger.info(`加载了 ${plugins.length} 个已安装插件`);
  return plugins;
}

/**
 * 安装插件
 * @param pluginPath 插件路径（本地路径或npm包名）
 */
export function installPlugin(pluginPath: string): Promise<boolean> {
  logger.info(`开始安装插件: ${pluginPath}`);

  return new Promise((resolve, reject) => {
    ensurePluginDirs();

    // 判断是本地路径还是npm包名
    if (fs.existsSync(pluginPath)) {
      // 本地路径，复制到插件目录
      const pluginName = path.basename(pluginPath);
      const targetDir = path.join(PLUGIN_DIR, pluginName);

      logger.info(`安装本地插件: ${pluginPath} -> ${targetDir}`);

      try {
        // 递归复制目录
        copyDirRecursive(pluginPath, targetDir);
        logger.info(`本地插件安装成功: ${pluginName}`);
        resolve(true);
      } catch (err) {
        logger.error(`安装本地插件失败: ${err}`);
        reject(err);
      }
    } else {
      // npm包名，使用npm安装
      const npmCommand = `npm install ${pluginPath} --prefix ${PLUGIN_DIR}`;
      logger.info(`使用npm安装插件: ${npmCommand}`);

      exec(npmCommand, (error, stdout, stderr) => {
        if (error) {
          logger.error(`npm安装失败: ${error.message}`);
          logger.error(`stderr: ${stderr}`);
          reject(error);
          return;
        }

        logger.info(`npm安装输出: ${stdout}`);
        logger.info(`npm插件安装成功: ${pluginPath}`);
        resolve(true);
      });
    }
  });
}

/**
 * 卸载插件
 * @param pluginId 插件ID
 */
export function uninstallPlugin(pluginId: string): Promise<boolean> {
  logger.info(`开始卸载插件: ${pluginId}`);

  return new Promise((resolve, reject) => {
    ensurePluginDirs();

    // 查找插件目录
    const entries = fs.readdirSync(PLUGIN_DIR, { withFileTypes: true });
    const pluginFolders = entries.filter((entry) => entry.isDirectory());

    logger.debug(`扫描目录寻找插件: ${pluginFolders.length} 个文件夹`);

    for (const folder of pluginFolders) {
      const pluginDir = path.join(PLUGIN_DIR, folder.name);
      const packageJsonPath = path.join(pluginDir, 'package.json');

      // 检查是否存在package.json
      if (!fs.existsSync(packageJsonPath)) {
        logger.debug(`跳过 ${folder.name}: 没有package.json`);
        continue;
      }

      try {
        // 读取package.json
        const packageJson = JSON.parse(
          fs.readFileSync(packageJsonPath, 'utf-8')
        ) as PluginPackage;
        logger.debug(`检查插件 ${packageJson.name} 是否匹配ID: ${pluginId}`);

        // 检查是否是目标插件
        if (
          packageJson.gitokPlugin &&
          packageJson.gitokPlugin.id === pluginId
        ) {
          logger.info(
            `找到匹配的插件: ${packageJson.name} (${pluginId})，开始卸载`
          );

          // 删除插件目录
          fs.rmdirSync(pluginDir, { recursive: true });
          logger.info(`插件已成功卸载: ${pluginId}`);
          resolve(true);
          return;
        }
      } catch (err) {
        logger.error(`解析插件package.json失败: ${packageJsonPath}`, {
          error: err instanceof Error ? err.message : String(err),
        });
      }
    }

    logger.error(`卸载失败: 未找到插件 ${pluginId}`);
    reject(new Error(`未找到插件: ${pluginId}`));
  });
}

/**
 * 递归复制目录
 */
function copyDirRecursive(src: string, dest: string) {
  logger.debug(`递归复制: ${src} -> ${dest}`);

  // 确保目标目录存在
  if (!fs.existsSync(dest)) {
    fs.mkdirSync(dest, { recursive: true });
  }

  // 获取源目录中的所有文件和子目录
  const entries = fs.readdirSync(src, { withFileTypes: true });

  // 复制每个文件和子目录
  for (const entry of entries) {
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);

    if (entry.isDirectory()) {
      // 递归复制子目录
      copyDirRecursive(srcPath, destPath);
    } else {
      // 复制文件
      fs.copyFileSync(srcPath, destPath);
      logger.debug(`已复制文件: ${entry.name}`);
    }
  }
}

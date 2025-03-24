/**
 * 获取当前活跃应用信息的接口
 */
interface ActiveApplication {
  name: string;
  bundleId: string;
  bundlePath: string;
}

/**
 * 获取当前活跃（前台）应用的信息
 * @returns {ActiveApplication} 活跃应用的信息
 * @throws {Error} 如果无法获取活跃应用信息
 */
export function getFrontmostApplication(): ActiveApplication {
  try {
    // 加载原生模块
    const nativeModule = require('../build/Release/active-app.node');
    return nativeModule.getFrontmostApplication();
  } catch (error) {
    throw new Error(`加载活跃应用原生模块失败: ${error}`);
  }
}

import chalk from "chalk";

// 格式化错误信息的辅助函数
export function formatError(error: any): string {
    const errorMessage = error.message || String(error);
    const errorStack = error.stack ? `\n调用栈：${error.stack}` : '';
    return chalk.red(errorMessage) + chalk.gray(errorStack);
}

// 延迟函数
export const delay = (ms: number) => new Promise(resolve => setTimeout(resolve, ms)); 
#!/usr/bin/env node

/**
 * Command键双击监听器CLI工具
 *
 * 此工具用于快速测试Command键双击监听器是否正常工作
 */

import { CommandKeyListener } from "../dist/index.js"

// 显示标题
console.log("\n===================================")
console.log("🖥  Command键双击监听器测试工具")
console.log("===================================\n")

// 创建监听器实例
const listener = new CommandKeyListener()

// 监听Command键双击事件
listener.on("command-double-press", () => {
    console.log("\n✨ 检测到Command键双击!\n")
})

// 启动监听器
console.log("🔄 启动监听器...")
listener.start().then((success) => {
    if (success) {
        console.log("✅ 监听器已启动成功")
        console.log("\n请尝试双击Command(⌘)键，按Ctrl+C退出程序\n")
    } else {
        console.error("❌ 监听器启动失败")
        process.exit(1)
    }
})

// 设置优雅退出
process.on("SIGINT", () => {
    console.log("\n\n🔄 停止监听器...")
    listener.stop()
    console.log("👋 监听器已停止，程序退出")
    process.exit(0)
})

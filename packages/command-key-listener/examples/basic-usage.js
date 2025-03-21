/**
 * Command键双击监听器使用示例
 *
 * 此示例展示了如何使用CommandKeyListener捕获Command键双击事件
 */

import { CommandKeyListener } from "../dist/index.js"

// 创建监听器实例
const listener = new CommandKeyListener()

// 监听Command键双击事件
listener.on("command-double-press", () => {
    console.log("✅ 检测到Command键双击!")

    // 在这里处理你的业务逻辑
    // 例如显示/隐藏窗口等
})

// 启动监听器
console.log("启动Command键双击监听器...")
listener.start().then((success) => {
    if (success) {
        console.log("✅ 监听器已成功启动")
        console.log("现在可以尝试双击Command键，按Ctrl+C退出程序")
    } else {
        console.error("❌ 监听器启动失败")
        process.exit(1)
    }
})

// 设置优雅退出
process.on("SIGINT", () => {
    console.log("\n停止监听器...")
    listener.stop()
    console.log("✅ 监听器已停止，程序退出")
    process.exit(0)
})

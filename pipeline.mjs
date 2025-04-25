import { spawn } from "child_process"

const spawnAsync = (command, args, options) => {
    return new Promise((resolve, reject) => {
        const commandString = `${command} ${args.join(" ")}`
        console.log(`\n[build] Starting: ${commandString}`)
        console.log(`[build] Working directory: ${options.cwd || process.cwd()}`)

        const child = spawn(command, args, options)

        child.on("exit", (code) => {
            if (code === 0) {
                console.log(`[build] ✅ Successfully completed: ${commandString}\n`)
                resolve()
            } else {
                console.error(`[build] ❌ Command failed with code ${code}: ${commandString}`)
                reject(new Error(`Command failed with code ${code}: ${commandString}`))
            }
        })

        child.on("error", (err) => {
            console.error(`[build] ❌ Command error: ${commandString}`)
            console.error(`[build] Error details: ${err.message}`)
            reject(err)
        })
    })
}

;(async () => {
    try {
        console.log("\n[pipeline] 🚀 Starting development build process...")

        // 构建 client
        console.log("\n[pipeline] 📦 Building client package...")
        await spawnAsync("pnpm", ["--filter", "vite-project", "run", "build"], {
            stdio: "inherit",
            shell: true
        })

        // 构建 extension
        console.log("\n[pipeline] 🔧 Building VS Code extension...")
        await spawnAsync("pnpm", ["--filter", "smart-buddy", "run", "build"], {
            stdio: "inherit",
            shell: true
        })

        // 启动 VS Code
        console.log("\n[pipeline] 🚀 Launching VS Code with extension...")
        const vscode = spawn("code", ["--extensionDevelopmentPath", "./packages/vsc_extension"], {
            stdio: "inherit",
            shell: true
        })

        // 处理进程退出
        vscode.on("close", (code) => {
            if (code === 0) {
                console.log(`\n[pipeline] ✨ VS Code closed successfully`)
            } else {
                console.log(`\n[pipeline] VS Code exited with code ${code}`)
            }
            process.exit(code)
        })

        // 处理错误
        vscode.on("error", (err) => {
            console.error("\n[pipeline] ❌ Failed to start VS Code:", err)
            process.exit(1)
        })
    } catch (error) {
        console.error("\n[pipeline] ❌ Build failed:", error)
        process.exit(1)
    }
})()

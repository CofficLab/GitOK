import { promises as fs } from "fs"
import path from "path"
import { fileURLToPath } from "url"

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const rootDir = path.resolve(__dirname, "..")

async function copyNativeModule() {
    const sourceFile = path.join(
        rootDir,
        "native/command-key-listener/build/Release/command_key_listener.node"
    )
    const destDir = path.join(rootDir, "out/native/command-key-listener/build/Release")
    const destFile = path.join(destDir, "command_key_listener.node")

    try {
        // 确保目标目录存在
        await fs.mkdir(destDir, { recursive: true })

        // 复制文件
        await fs.copyFile(sourceFile, destFile)
        console.log(`成功复制原生模块: ${sourceFile} -> ${destFile}`)
    } catch (err) {
        console.error("复制原生模块时出错:", err)
    }
}

// 执行复制
copyNativeModule().catch((err) => {
    console.error("无法复制原生模块:", err)
    process.exit(1)
})

import { exec, execSync } from "child_process"

const childOptions = {
    shell: "bash",
    stdio: "inherit"
}

;(async () => {
    await Promise.all([
        exec("cd packages/client/ && npm run build", childOptions),
        exec("cd packages/vsc_extension/ && npm run build", childOptions)
    ])
    execSync("cd packages/vsc_extension/ && npm run dev:vscode", childOptions)
})()

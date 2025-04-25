import { fileIpc } from '@/renderer/src/ipc/file-ipc'

export function useDirectory() {
    const openDirectory = async (dir: string | null) => {
        if (!dir) return
        try {
            await fileIpc.openFolder(dir)
        } catch (error) {
            console.error(`打开目录失败: ${error}`)
        }
    }

    return {
        openDirectory,
    }
}
import { ipcApi } from '@renderer/api/ipc-api'

export function useDirectory() {
    const openDirectory = async (dir: string | null) => {
        if (!dir) return
        try {
            await ipcApi.openFolder(dir)
        } catch (error) {
            console.error(`打开目录失败: ${error}`)
        }
    }

    return {
        openDirectory,
    }
}
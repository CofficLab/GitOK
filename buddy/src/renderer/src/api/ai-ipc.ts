import { ChatMessage, IPC_METHODS, IpcResponse, StreamChunkResponse, StreamDoneResponse } from "@coffic/buddy-types";

const ipc = window.electron.ipc;

export const aiIpc = {
    async send(messages: ChatMessage[]): Promise<string> {
        const response: IpcResponse<unknown> = await ipc.invoke(IPC_METHODS.AI_CHAT_SEND, messages);
        if (response.success) {
            return response.data as string ?? '';
        } else {
            throw new Error(response.error);
        }
    },

    onAiChatStreamChunk(callback: (response: StreamChunkResponse) => void): () => void {
        const handler = (_: any, response: StreamChunkResponse) => callback(response);
        ipc.receive(IPC_METHODS.AI_CHAT_STREAM_CHUNK, handler);
        return () => {
            ipc.removeListener(IPC_METHODS.AI_CHAT_STREAM_CHUNK, handler);
        };
    },

    onAiChatStreamDone(callback: (response: StreamDoneResponse) => void): () => void {
        const handler = (_: any, response: StreamDoneResponse) => callback(response);
        ipc.on(IPC_METHODS.AI_CHAT_STREAM_DONE, handler);
        return () => {
            ipc.removeListener(IPC_METHODS.AI_CHAT_STREAM_DONE, handler);
        };
    },

    async aiChatCancel(requestId: string, reason: string): Promise<boolean> {
        return await ipc.invoke(IPC_METHODS.AI_CHAT_CANCEL, requestId, reason);
    },
};
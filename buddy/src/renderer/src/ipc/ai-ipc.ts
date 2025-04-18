import { ChatMessage, IpcResponse, StreamChunkResponse, StreamDoneResponse } from "@coffic/buddy-types";
import { IPC_METHODS } from "@/types/ipc-methods.js";

const ipc = window.ipc;

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
        const handler = (response: any) => {
            callback((response as StreamChunkResponse))
        };

        ipc.receive(IPC_METHODS.AI_CHAT_STREAM_CHUNK, handler)

        return () => {
            ipc.removeListener(IPC_METHODS.AI_CHAT_STREAM_CHUNK, handler);
        };
    },

    onAiChatStreamDone(callback: (response: StreamDoneResponse) => void): () => void {
        const handler = (response: any) => {
            callback((response as StreamDoneResponse))
        };

        ipc.receive(IPC_METHODS.AI_CHAT_STREAM_DONE, handler)

        return () => {
            ipc.removeListener(IPC_METHODS.AI_CHAT_STREAM_DONE, handler);
        };
    },

    async aiChatCancel(requestId: string, reason: string): Promise<boolean> {
        const response: IpcResponse<any> = await ipc.invoke(IPC_METHODS.AI_CHAT_CANCEL, requestId, reason);

        if (response.success) {
            return true
        } else {
            return false
        }
    },
};
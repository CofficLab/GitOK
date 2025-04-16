/// <reference types="vite/client" />

import { IpcApi } from "@coffic/buddy-types";


declare global {
  interface Window {
    ipc: IpcApi;
  }
}

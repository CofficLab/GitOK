/// <reference types="vite/client" />

import { ElectronApi } from "@coffic/buddy-types";


declare global {
  interface Window {
    electron: ElectronApi;
  }
}

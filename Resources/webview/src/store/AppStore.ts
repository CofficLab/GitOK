import { defineStore } from 'pinia'
import webkit from '../entities/WebKit'

export const useAppStore = defineStore('app-store', {
    state: () => {
        return {
            ready: false,
            original: "",
            modified: ""
        }
    },

    actions: {
        setOriginal: function (data: string) {
            console.log('🍋 AppStore: setOriginal')
            this.original = data
        },
        setModified: function (data: string) {
            console.log('🍋 AppStore: setModified')
            this.modified = data
        },
        setReady() {
            this.ready = true
            webkit.pageLoaded()
        },
    },
})
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
        setTextsWithObject(object: { original: string, modified: string }) {
            console.log('🍋 AppStore: setTextsWithObject')
            this.setTexts(object.original, object.modified)
        },

        setTexts(original: string, modified: string) {
            console.log('🍋 AppStore: setTexts')
            this.original = original
            this.modified = modified
        },

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